class_name Unit
extends CharacterBody2D

@export var attack_animations : Dictionary = {}
@export var attack_range := 100.0
@export var attack_cooldown := 0.5
@export var confirm_acks := []
@export var cost : Dictionary = {
	enums.e_resource_type.gold: 0.0,
	enums.e_resource_type.wood: 0.0,
	enums.e_resource_type.meat: 0.0,
	enums.e_resource_type.supply: 1
}
@export var damage : float = 10.0
@export var health : float = 50.0
@export var max_health : float = 50.0
@export var movement_speed: float = 100.0
@export var team : enums.e_team

# Public Vars
var details
var group_guid
var current_cell: SelectionGridCell:
	get:
		return current_cell
	set(value):
		current_cell = value

# Private Vars
var _attack_timer : Timer
var _attacking := false
var _audio_stream_player := AudioStreamPlayer2D.new()
var _audio_streams := []
var _current_cell_label
var _current_order_type : enums.e_order_type
var _health_bar : ProgressBar
var _in_selection := false
var _targetted_enemy

@onready var attack_area: Area2D = $AttackArea
@onready var anim_sprite : AnimatedSprite2D = $AnimatedSprite2D
@onready var navigation_agent: NavigationAgent2D = get_node("NavigationAgent2D")
@onready var selection_hover_area: Area2D = $SelectionHoverArea

func _ready() -> void:
	add_to_group(Globals.unit_group)
	ResourceManager._update_resource(cost[enums.e_resource_type.supply], enums.e_resource_type.supply)
	navigation_agent.debug_enabled = Globals.debug
	z_index = Globals.unit_z_index
	add_child(_audio_stream_player)
	
	# add health bar UI
	_health_bar = ProgressBar.new()
	_health_bar.name = "HealthBar"
	_health_bar.max_value = max_health
	_health_bar.value = max_health
	_health_bar.position = Vector2(-50, -100)
	_health_bar.add_theme_font_size_override(&"font_size", 1)
	if $ProgressBar != null:
		print($ProgressBar.size)
	_health_bar.show_percentage = false
	_health_bar.size = Vector2(100, 5)
	_health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var _health_bar_style_box = StyleBoxFlat.new()
	_health_bar_style_box.bg_color = Color.RED
	_health_bar.add_theme_stylebox_override(&"fill", _health_bar_style_box)
	add_child(_health_bar)
	
	# setup attack area collision shape radius
	var attack_area_collision_shape = attack_area.get_child(0) 
	attack_area_collision_shape.shape.radius = attack_range
	
	# __________________________________________________________________________
	# Debug name text
	var label = Label.new()
	label.text = "%s" % name
	add_child(label)
	label.position = Vector2(0, -100) # is relative pos
	
	# debug current cell text
	_current_cell_label = Label.new()
	add_child(_current_cell_label)
	_current_cell_label.position = Vector2(0, 25) # is relative pos
	# __________________________________________________________________________
	
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	attack_area.body_exited.connect(_on_attack_area_body_exited)
	navigation_agent.navigation_finished.connect(_on_navigation_finished)
	navigation_agent.velocity_computed.connect(Callable(_on_velocity_computed))
	selection_hover_area.mouse_entered.connect(_on_mouse_overlap)
	selection_hover_area.mouse_exited.connect(_on_mouse_exit)
	
	# ui detail setup
	var ui_detail_one = UI_Detail.new()
	ui_detail_one.image_one_path = "res://art/icons/RPG Graphics Pack - Icons/Pack 1A-Renamed/boot/boot_03.png"
	ui_detail_one.detail_one = movement_speed
	var unit_picture_path = "res://art/Tiny Swords (Update 010)/Factions/Knights/Troops/Pawn/Blue/Pawn_Blue-still.png"
	details = [ui_detail_one, unit_picture_path]
	
	# audio streams for acks
	confirm_acks.append(load("res://sound/LEOHPAZ_Command_Speech/Human/Human_Confirm_1.wav"))
	confirm_acks.append(load("res://sound/LEOHPAZ_Command_Speech/Human/Human_Confirm_2.wav"))
	confirm_acks.append(load("res://sound/LEOHPAZ_Command_Speech/Human/Human_Confirm_3.wav"))
	
	var clean_timer = Timer.new()
	clean_timer.wait_time = .5
	clean_timer.timeout.connect(func(): 
		var stream = _audio_streams.pop_back()
		if stream != null and !stream.is_queued_for_deletion() and !stream.playing:
			stream.queue_free()
		elif stream != null:
			_audio_streams.push_back(stream)
	)
	add_child(clean_timer)
	clean_timer.start()
	
	_attack_timer = Timer.new()
	_attack_timer.wait_time = attack_cooldown
	_attack_timer.timeout.connect(_on_atack)
	add_child(_attack_timer)

func _physics_process(delta: float) -> void:
	var next_path_position: Vector2 = navigation_agent.get_next_path_position()
	var new_velocity: Vector2 = global_position.direction_to(next_path_position) * movement_speed
	
	if navigation_agent.avoidance_enabled:
		navigation_agent.set_velocity(new_velocity)
	else:
		_on_velocity_computed(new_velocity)
	
	if !_attacking:
		if new_velocity.dot(Vector2.RIGHT) < 0:
			anim_sprite.flip_h = true
		else:
			anim_sprite.flip_h = false
	
	if current_cell != null:
		DebugDraw2d.rect(current_cell.position)

func can_afford_to_build() -> bool:
	var can_afford = true
	for r in cost:
		match r:
			enums.e_resource_type.gold:
				if ResourceManager.gold < cost[r]:
					can_afford = false
					break
			enums.e_resource_type.wood:
				if ResourceManager.wood < cost[r]:
					can_afford = false
					break
			enums.e_resource_type.meat:
				if ResourceManager.meat < cost[r]:
					can_afford = false
					break
			enums.e_resource_type.supply:
				if ResourceManager.supply_cap < cost[r] + ResourceManager.supply:
					can_afford = false
					break
	
	return can_afford

func order_move(in_goal, in_order_type : enums.e_order_type, silent := false) -> void:
	if in_order_type != enums.e_order_type.attack:
		_stop_attacking()
	
	_acknowledge(silent)
	anim_sprite.animation = "run"
	set_movement_target(in_goal)

func order_attack(enemy):
	_targetted_enemy = enemy
	print("Attacking enemy %s" % enemy.name)
	
	if (attack_area.overlaps_body(_targetted_enemy)):
		_begin_attacking()
	else:
		order_move(enemy.position, enums.e_order_type.attack)

func stop() -> void:
	set_movement_target(position)

func set_movement_target(movement_target: Vector2) -> void:
	navigation_agent.set_target_position(movement_target)

func set_selection_circle_visible(visible) -> void:
	$"Selection Circle".visible = visible

func take_damage(damage : float) -> void:
	health -= damage
	_health_bar.value = health
	if health <= 0:
		_die()

func _acknowledge(silent : bool) -> void:
	var acknowledger = UnitManager.group_get_acknowledger(group_guid)
	if !silent and acknowledger == null or acknowledger == self:
		var temp_stream = AudioStreamPlayer2D.new()
		temp_stream.stream = confirm_acks[randi_range(0, len(confirm_acks) - 1)]
		_audio_streams.push_back(temp_stream)
		add_child(temp_stream)
		temp_stream.play()
		if group_guid != null:
			UnitManager.group_set_acknowledger(group_guid, self)

func _begin_attacking() -> void:
	_attacking = true
	anim_sprite.animation = _select_attack_animation()
	_on_atack()
	_attack_timer.start()

func _die() -> void:
	queue_free()

func _on_mouse_overlap() -> void:
	SelectionHandler.mouse_hovered_unit = self

func _on_mouse_exit() -> void:
	if SelectionHandler.mouse_hovered_unit == self:
		SelectionHandler.mouse_hovered_unit = null

func _on_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
	move_and_slide()

func _on_navigation_finished() -> void:
	anim_sprite.animation = "idle"
	# the goal of checking that the current order type is move is to prevent
	# the unit stopping early before reaching the enemy/resource
	if _current_order_type == enums.e_order_type.move and group_guid != null and !UnitManager.groups[group_guid].group_stopping:
		UnitManager.groups[group_guid].group_stopping = true
		_find_close_in_group_units_and_stop_them()
	
	# TODO: auto-attack
	#if _current_order_type != enums.e_order_type.attack:
		#_find_closest_enemy()

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body != _targetted_enemy:
		return
	
	stop()
	await navigation_agent.navigation_finished
	_begin_attacking()

func _on_attack_area_body_exited(body: Node2D) -> void:
	pass # Replace with function body.

func _on_atack() -> void:
	if _targetted_enemy == null:
		_stop_attacking()
		return
	
	_targetted_enemy.take_damage(damage)

func _select_attack_animation() -> StringName:
	var attack_animation := &""
	var _unit_to_enemy = position.direction_to(_targetted_enemy.position)
	var _up_dot_unit_to_enemy = Vector2.UP.dot(_unit_to_enemy)
	var _right_dot_unit_to_enemy = Vector2.RIGHT.dot(_unit_to_enemy)
	
	# up or down takes over
	if abs(_up_dot_unit_to_enemy) > abs(_right_dot_unit_to_enemy):
		if _up_dot_unit_to_enemy > 0:
			attack_animation = attack_animations["up"][0]
		else:
			attack_animation = attack_animations["down"][0]
	else:
		attack_animation = attack_animations["front"][0]
		if _right_dot_unit_to_enemy > 0:
			anim_sprite.flip_h = false
		else:
			anim_sprite.flip_h = true
	
	return attack_animation

func _stop_attacking() -> void:
	_targetted_enemy = null
	_attacking = false
	_attack_timer.stop()
	anim_sprite.animation = "idle"

func _find_close_in_group_units_and_stop_them() -> void:
	for a in $SearchAreaSmall.get_overlapping_areas():
		if a.owner == null:
			continue
		if a.owner.is_in_group(Globals.unit_group):
			var unit = a.owner as Unit
			if UnitManager.groups.has(group_guid) and unit.group_guid == group_guid:
				unit.stop()
	UnitManager.groups[group_guid].group_stopping = false
