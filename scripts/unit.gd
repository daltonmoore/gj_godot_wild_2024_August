class_name Unit
extends CharacterBody2D

@export var attack_animations : Dictionary = {}
@export var movement_speed: float = 100.0
@export var cost : Dictionary = {
	enums.e_resource_type.gold: 0.0,
	enums.e_resource_type.wood: 0.0,
	enums.e_resource_type.meat: 0.0,
	enums.e_resource_type.supply: 1
	}
@export var confirm_acks := []
@export var team : enums.e_team
@export var attack_range := 100.0

# Public Vars
var details
var group_guid
var current_cell: SelectionGridCell:
	get:
		return current_cell
	set(value):
		current_cell = value

# Private Vars
var _audio_stream_player := AudioStreamPlayer2D.new()
var _audio_streams := []
var _current_cell_label
var _current_order_type : enums.e_order_type
var _in_selection := false
var _targetted_enemy

@onready var anim_sprite : AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_range_area : Area2D = $AttackRangeArea
@onready var facing : RayCast2D = $Facing
@onready var navigation_agent: NavigationAgent2D = get_node("NavigationAgent2D")

func _ready() -> void:
	navigation_agent.debug_enabled = Globals.debug
	add_to_group(Globals.unit_group)
	z_index = Globals.unit_z_index
	ResourceManager._update_resource(cost[enums.e_resource_type.supply], enums.e_resource_type.supply)
	
	confirm_acks.append(load("res://sound/LEOHPAZ_Command_Speech/Human/Human_Confirm_1.wav"))
	confirm_acks.append(load("res://sound/LEOHPAZ_Command_Speech/Human/Human_Confirm_2.wav"))
	confirm_acks.append(load("res://sound/LEOHPAZ_Command_Speech/Human/Human_Confirm_3.wav"))
	add_child(_audio_stream_player)
	
	if attack_range_area != null:
		attack_range_area.body_entered.connect(_on_attack_range_body_entered)
		attack_range_area.body_exited.connect(_on_attack_range_body_exited)
	
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
	
	navigation_agent.navigation_finished.connect(_on_navigation_finished)
	navigation_agent.velocity_computed.connect(Callable(_on_velocity_computed))
	$Area2D.mouse_entered.connect(_on_mouse_overlap)
	$Area2D.mouse_exited.connect(_on_mouse_exit)
	
	var ui_detail_one = UI_Detail.new()
	ui_detail_one.image_one_path = "res://art/icons/RPG Graphics Pack - Icons/Pack 1A-Renamed/boot/boot_03.png"
	ui_detail_one.detail_one = movement_speed
	var unit_picture_path = "res://art/Tiny Swords (Update 010)/Factions/Knights/Troops/Pawn/Blue/Pawn_Blue-still.png"
	details = [ui_detail_one, unit_picture_path]
	
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

func _physics_process(delta: float) -> void:
	var next_path_position: Vector2 = navigation_agent.get_next_path_position()
	var new_velocity: Vector2 = global_position.direction_to(next_path_position) * movement_speed
	
	if navigation_agent.avoidance_enabled:
		navigation_agent.set_velocity(new_velocity)
	else:
		_on_velocity_computed(new_velocity)
	
	if facing != null:
		facing.target_position = new_velocity
		DebugDraw2d.arrow_vector(position, new_velocity)
	
	if new_velocity.dot(Vector2.RIGHT) < 0:
		anim_sprite.flip_h = true
	else:
		anim_sprite.flip_h = false
	
	if current_cell != null:
		DebugDraw2d.rect(current_cell.position)
	
	if _targetted_enemy != null: #and  <= attack_range:
		print(position.distance_to(_targetted_enemy.position))
		if position.distance_to(_targetted_enemy.position) <= attack_range:
			DebugDraw2d.circle(position, attack_range, 16, Color.RED, 1, 0)

func order_move(in_goal, in_order_type : enums.e_order_type, silent := false) -> void:
	_acknowledge(silent)
	anim_sprite.animation = "run"
	set_movement_target(in_goal)

func order_attack(enemy):
	_targetted_enemy = enemy
	print("Attacking enemy %s" % enemy.name)
	order_move(enemy.position, enums.e_order_type.attack)

func stop() -> void:
	set_movement_target(position)

func set_movement_target(movement_target: Vector2) -> void:
	navigation_agent.set_target_position(movement_target)

func set_selection_circle_visible(visible) -> void:
	$"Selection Circle".visible = visible

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

func _on_attack_range_body_entered(body: Node2D) -> void:
	push_warning("Not doing anything when attack range area is entered")
	return
	if body != _targetted_enemy:
		return
	
	stop()
	await navigation_agent.navigation_finished
	_begin_attacking()

func _on_attack_range_body_exited(body: Node2D) -> void:
	pass # Replace with function body.

func _acknowledge(silent : bool) -> void:
	var acknowledger = UnitManager.group_get_acknowledger(group_guid)
	if !silent and acknowledger == null or acknowledger == self:
		var temp_stream = AudioStreamPlayer2D.new()
		prints("created stream %s" % temp_stream)
		temp_stream.stream = confirm_acks[randi_range(0, len(confirm_acks) - 1)]
		_audio_streams.push_back(temp_stream)
		add_child(temp_stream)
		temp_stream.play()
		if group_guid != null:
			UnitManager.group_set_acknowledger(group_guid, self)

func _begin_attacking() -> void:
	anim_sprite.animation = "front_attack_1"
	var _unit_to_enemy = position.direction_to(_targetted_enemy.position)
	var _up_dot_unit_to_enemy = Vector2.UP.dot(_unit_to_enemy)
	var _right_dot_unit_to_enemy = Vector2.RIGHT.dot(_unit_to_enemy)
	print("above dot %s" % _up_dot_unit_to_enemy)
	print("right dot %s" % _right_dot_unit_to_enemy)
	
	# up or down takes over
	if abs(_up_dot_unit_to_enemy) > abs(_right_dot_unit_to_enemy):
		if _up_dot_unit_to_enemy > 0:
			anim_sprite.animation = attack_animations["up"][0]
		else:
			anim_sprite.animation = attack_animations["down"][0]
	else:
		anim_sprite.animation = attack_animations["front"][0]
		if _right_dot_unit_to_enemy > 0:
			anim_sprite.flip_h = false
		else:
			anim_sprite.flip_h = true

func _find_close_in_group_units_and_stop_them() -> void:
	for a in $SearchAreaSmall.get_overlapping_areas():
		if a.owner == null:
			continue
		if a.owner.is_in_group(Globals.unit_group):
			var unit = a.owner as Unit
			if UnitManager.groups.has(group_guid) and unit.group_guid == group_guid:
				unit.stop()
	UnitManager.groups[group_guid].group_stopping = false
