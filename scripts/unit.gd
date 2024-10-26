class_name Unit
extends CharacterBody2D

#region Signals
signal sig_dying(this)
#endregion

#region Export
@export var attack_animations : Dictionary = {
	"front": [],
	"up": [],
	"down": [],
}
@export var attack_range := 100.0
@export var attack_cooldown := 0.5
@export var confirm_acks : Array[AudioStream] = []
@export var cost : Dictionary = {
	enums.e_resource_type.gold: 0.0,
	enums.e_resource_type.wood: 0.0,
	enums.e_resource_type.meat: 0.0,
	enums.e_resource_type.supply: 1
}
@export var damage : float = 10.0
@export var engage_sounds : Array[AudioStream] = []
@export var health : float = 50.0
@export var hurt_sounds : Array[AudioStream] = []
@export var max_health : float = 50.0
@export var movement_speed: float = 100.0
@export var weapon_sounds : Array[AudioStream] = []
@export var team : enums.e_team
#endregion

#region Public Vars
var details
var group_guid
var current_cell: SelectionGridCell:
	get:
		return current_cell
	set(value):
		current_cell = value
#endregion

#region Private Vars
var _attack_timer : Timer
var _audio_streams := []
var _corpse_scene := load("res://scenes/corpse.tscn")
var _current_cell_label : Label
var _current_order_type : enums.e_order_type
var _death_animated_sprite : AnimatedSprite2D # not used for death animation
var _is_attacking := false
var _is_dying := false
var _in_selection := false
var _strike_frame_index := 3 # the frame where the attack animation looks like it is connecting
var _weapon_audio_stream := AudioStreamPlayer2D.new()
var _targetted_enemy : Unit
#endregion

#region OnReady
@onready var attack_area: Area2D = $AttackArea
@onready var anim_sprite : AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $HealthBar
@onready var navigation_agent: NavigationAgent2D = get_node("NavigationAgent2D")
@onready var selection_hover_area: Area2D = $SelectionHoverArea
@onready var vision_area: Area2D = $VisionArea
#endregion

func _ready() -> void:
	for anim_name in anim_sprite.sprite_frames.get_animation_names():
		if Globals.has_pattern("down.*attack", anim_name):
			attack_animations["down"].append(anim_name)
		elif Globals.has_pattern("front.*attack", anim_name):
			attack_animations["front"].append(anim_name)
		elif Globals.has_pattern("up.*attack", anim_name):
			attack_animations["up"].append(anim_name)
	
	z_index = Globals.unit_z_index
	ResourceManager._update_resource(cost[enums.e_resource_type.supply], enums.e_resource_type.supply)
	navigation_agent.debug_enabled = Globals.debug
	add_to_group(Globals.unit_group) # TODO: Is this used anymore?
	_setup_audio_streams()
	_setup_health_bar()
	_setup_signal_connections()
	
	if Globals.debug:
		_setup_debug_labels()
	
	# setup attack area collision shape radius
	var attack_area_collision_shape = attack_area.get_child(0) 
	attack_area_collision_shape.shape.radius = attack_range
	
	# ui detail setup
	var ui_detail_one = UI_Detail.new()
	ui_detail_one.image_one_path = "res://art/icons/RPG Graphics Pack - Icons/Pack 1A-Renamed/boot/boot_03.png"
	ui_detail_one.detail_one = movement_speed
	var unit_picture_path = "res://art/Tiny Swords (Update 010)/Factions/Knights/Troops/Pawn/Blue/Pawn_Blue-still.png"
	details = [ui_detail_one, unit_picture_path]
	
	_attack_timer = Timer.new()
	_attack_timer.wait_time = attack_cooldown
	_attack_timer.timeout.connect(_on_atack)
	add_child(_attack_timer)

func _physics_process(delta: float) -> void:
	if _is_dying:
		return
	
	var next_path_position: Vector2 = navigation_agent.get_next_path_position()
	var new_velocity: Vector2 = global_position.direction_to(next_path_position) * movement_speed
	
	if navigation_agent.avoidance_enabled:
		navigation_agent.set_velocity(new_velocity)
	else:
		_on_velocity_computed(new_velocity)
	
	if !_is_attacking:
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
	_create_one_shot_audio_stream("attacking_audio_stream", engage_sounds)
	_targetted_enemy = enemy
	print("Attacking enemy %s" % enemy.name)
	
	if !_targetted_enemy.get_is_dying() and !_targetted_enemy.sig_dying.is_connected(_on_target_die):
		_targetted_enemy.sig_dying.connect(_on_target_die)
	
	if (attack_area.overlaps_body(_targetted_enemy)):
		_begin_attacking()
	else:
		order_move(enemy.position, enums.e_order_type.attack, true)

func get_is_dying() -> bool:
	return _is_dying

func stop_moving() -> void:
	set_movement_target(position)

func set_movement_target(movement_target: Vector2) -> void:
	navigation_agent.set_target_position(movement_target)

func set_selection_circle_visible(visible) -> void:
	$"Selection Circle".visible = visible

func take_damage(damage: float) -> void:
	if _is_dying:
		return
	
	_create_one_shot_audio_stream("hurt_audio_stream", hurt_sounds)
	
	health -= damage
	health_bar.value = health
	if health <= 0:
		_die()

func _acknowledge(silent: bool) -> void:
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
	_is_attacking = true
	anim_sprite.animation = _select_attack_animation()

func _create_one_shot_audio_stream(nombre: String, sound_array: Array[AudioStream]) -> void:
	if sound_array.size() == 0:
		push_warning("Cannot create one shot audio for empty array")
		return
	
	var audio_stream = AudioStreamPlayer2D.new()
	audio_stream.name = nombre + "_" + str(hash(Time.get_unix_time_from_system()))
	audio_stream.stream = sound_array[randi_range(0, sound_array.size() - 1)]
	add_child(audio_stream)
	audio_stream.play()
	audio_stream.finished.connect(
		func():
			audio_stream.queue_free()
	)

func _die() -> void:
	var instance = _corpse_scene.instantiate()
	get_tree().get_root().add_child(instance)
	instance.position = global_position
	anim_sprite.visible = false
	_is_dying = true
	#selection_hover_area.process_mode = Node.PROCESS_MODE_DISABLED
	#selection_hover_area.monitorable = false
	#selection_hover_area.monitoring = false
	#selection_hover_area.get_child(0).set_deferred(&"disabled", true)

	sig_dying.emit(self)
	if _in_selection:
		SelectionHandler.remove_from_selection(self)
	queue_free()

## You have to pass in the correct amount of StringNames in the anims array
## i.e. if the amount of rows in the full spritesheet is 2 then you need to pass
## 2 StringNames in the anims array
func _extract_sprite_frames(anims: Array[StringName], 
		texture_size: Vector2, 
		sprite_size: Vector2, 
		full_spritesheet: Texture2D) -> Array[SpriteFrames]:
	var sprite_frames_list : Array[SpriteFrames]
	var num_cols := int(texture_size.x / sprite_size.x)
	var num_rows := int(texture_size.y / sprite_size.y)
	
	for y in range(num_rows):
		if y >= anims.size():
			break
		
		var sprite_frames = SpriteFrames.new()
		sprite_frames.add_animation(anims[y])
		for x in range(num_cols):
			var frame_tex := AtlasTexture.new()
			frame_tex.atlas = full_spritesheet
			frame_tex.region = Rect2(Vector2(x, y) * sprite_size, sprite_size)
			sprite_frames.add_frame(anims[y], frame_tex, 1, y * num_cols + x)
		sprite_frames_list.append(sprite_frames)
	
	return sprite_frames_list

#region Listeners
func _on_anim_frame_changed() -> void:
	if !_is_attacking:
		return
	
	#check when we are rearing back if the target is dead
	if anim_sprite.frame < 3:
		if _targetted_enemy == null or _targetted_enemy.is_queued_for_deletion():
			_stop_attacking()
	elif anim_sprite.frame == 3:
		_on_atack()

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body != _targetted_enemy:
		return
	
	stop_moving()
	await navigation_agent.navigation_finished
	_begin_attacking()

func _on_attack_area_body_exited(body: Node2D) -> void:
	if body != _targetted_enemy or _targetted_enemy == null:
		return
	
	_is_attacking = false
	_attack_timer.stop()
	order_attack(_targetted_enemy)

func _on_atack() -> void:
	_weapon_audio_stream.stream = weapon_sounds[randi_range(0, weapon_sounds.size() - 1)]
	_weapon_audio_stream.play()
	_targetted_enemy.take_damage(damage)

func _on_mouse_overlap() -> void:
	SelectionHandler.mouse_hovered_unit = self #TODO: stop directly setting this

func _on_mouse_exit() -> void:
	if SelectionHandler.mouse_hovered_unit == self:
		SelectionHandler.mouse_hovered_unit = null

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

func _on_target_die(target) -> void:
	assert (target == _targetted_enemy)
	_targetted_enemy.sig_dying.disconnect(_on_target_die)
	_stop_attacking()

func _on_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
	move_and_slide()
#endregion

#region Setup
func _setup_audio_streams() -> void:
	add_child(_weapon_audio_stream)
	weapon_sounds.append(load("res://sound/Minifantasy_Weapons_SFX/Slash_Attacks/Slash_Attack_Sword_1.wav"))
	weapon_sounds.append(load("res://sound/Minifantasy_Weapons_SFX/Slash_Attacks/Slash_Attack_Sword_2.wav"))
	weapon_sounds.append(load("res://sound/Minifantasy_Weapons_SFX/Slash_Attacks/Slash_Attack_Sword_3.wav"))
	
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

# not good for death animation but could be good for another animation type maybe
func _setup_death_animated_sprite() -> void:
	_death_animated_sprite = AnimatedSprite2D.new()
	_death_animated_sprite.name = &"DeathAnimatedSprite_FromCode"
	
	var texture_size := Vector2(896, 256)
	var sprite_size := Vector2(128, 128)
	var full_spritesheet : Texture = load("res://art/Tiny Swords (Update 010)/Factions/Knights/Troops/Dead/Dead.png")
	var sprite_frames_array : Array[SpriteFrames] = _extract_sprite_frames([&"die"], texture_size, sprite_size, full_spritesheet)
	
	sprite_frames_array[0].set_animation_speed(&"die", 10)
	sprite_frames_array[0].set_animation_loop(&"die", false)
	
	_death_animated_sprite.sprite_frames = sprite_frames_array[0]
	add_child(_death_animated_sprite)

func _setup_debug_labels() -> void:
	# Debug name text
	var label = Label.new()
	label.text = "%s" % name
	add_child(label)
	label.position = Vector2(0, -100) # is relative pos
	
	# debug current cell text
	_current_cell_label = Label.new()
	add_child(_current_cell_label)
	_current_cell_label.position = Vector2(0, 25) # is relative pos

func _setup_health_bar() -> void:
	if health_bar == null: 
		return
	
	health_bar.max_value = max_health
	health_bar.value = max_health
	health_bar.position = Vector2(-50, -100)
	health_bar.add_theme_font_size_override(&"font_size", 1)
	health_bar.show_percentage = false
	health_bar.size = Vector2(100, 5)
	health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var _health_bar_style_box = StyleBoxFlat.new()
	_health_bar_style_box.bg_color = Color.RED
	health_bar.add_theme_stylebox_override(&"fill", _health_bar_style_box)

func _setup_signal_connections() -> void:
	anim_sprite.frame_changed.connect(_on_anim_frame_changed)
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	attack_area.body_exited.connect(_on_attack_area_body_exited)
	navigation_agent.navigation_finished.connect(_on_navigation_finished)
	navigation_agent.velocity_computed.connect(Callable(_on_velocity_computed))
	selection_hover_area.mouse_entered.connect(_on_mouse_overlap)
	selection_hover_area.mouse_exited.connect(_on_mouse_exit)
#endregion

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
	_is_attacking = false
	_attack_timer.stop()
	anim_sprite.animation = "idle"
	stop_moving()

func _find_close_in_group_units_and_stop_them() -> void:
	for a in $SearchAreaSmall.get_overlapping_areas():
		if a.owner == null:
			continue
		if a.owner.is_in_group(Globals.unit_group):
			var unit = a.owner as Unit
			if UnitManager.groups.has(group_guid) and unit.group_guid == group_guid:
				unit.stop()
	UnitManager.groups[group_guid].group_stopping = false
