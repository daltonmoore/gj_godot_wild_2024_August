class_name Unit
extends CharacterBody2D

@export_category("Combat")
@export var attack_range := 100.0
@export var attack_cooldown := 0.5
@export var can_attack_things := true
@export var damage: float = 10.0
@export var team: enums.e_team
@export var movement_speed: float =  100.0


@export_category("Animations")
@export var attack_animations : Dictionary = {
	"front": [],
	"up": [],
	"down": [],
}

@export var _run_animation := "run"
@export var debug_individual := false

@export_category("Misc")
@export var cost : Dictionary = {
	enums.e_resource_type.gold: 0.0,
	enums.e_resource_type.wood: 0.0,
	enums.e_resource_type.meat: 0.0,
	enums.e_resource_type.supply: 1
}

@export var unit_type: enums.E_UnitType

@export_category("Audio")
@export var confirm_acks: Array[AudioStream] = []
@export var engage_sounds : Array[AudioStream] = []
@export var weapon_sounds : Array[AudioStream] = []

var _anim_sprite : AnimatedSprite2D

var _audio_streams         := []
var _attack_timer: Timer
var _auto_attack           := true
var _cell_block: CellBlock =  CellBlock.new(self)

var _current_cell: SelectionGridCell:
	get: return _current_cell
	set(value): _current_cell = value

var _current_cell_label: Label
var _current_order_type: enums.e_order_type
var _death_animated_sprite: AnimatedSprite2D
var _group_guid
var _is_attacking          := false
var _is_idle               := true
var _strike_frame_index    := 3 # the frame where the attack animation looks like it is connecting
var _targeted_enemy: Attackable
var _weapon_audio_stream   := AudioStreamPlayer2D.new()
var _debug_label2: Label;

#region Node References
@onready var _attack_area: Area2D = $AttackArea
@onready var _attackable : Attackable = $Attackable
@onready var _debug_label: Label = $DebugLabel # for debugging targets
@onready var _navigation_agent: NavigationAgent2D = get_node("NavigationAgent2D")
@onready var _selection_hover_area: Area2D = $SelectionHoverArea
@onready var _vision_area: Area2D = $VisionArea
@onready var ui_details: UiDetails = $UiDetails
#endregion

#region Built-in Functions
func _ready() -> void:
	_anim_sprite = $AnimatedSprite2D
	# ------------------------------------
	if debug_individual or Globals.debug:
		_debug_label2 = Label.new()
		add_child(_debug_label2)
		if _debug_label != null:
			_debug_label2.position = _debug_label.position + Vector2(0,20)
		_debug_label2.text = "??"
	# ------------------------------------
	z_index = Globals.default_z_index
	ResourceManager._update_resource(cost[enums.e_resource_type.supply], enums.e_resource_type.supply)
	add_to_group(Globals.unit_group) # TODO: Is this used anymore?
	
	_setup_attack()
	_setup_audio_streams()
	_setup_signal_connections()
	_setup_debug()
	
	await get_tree().process_frame
	_cell_block.block_cell()


func _setup_debug() -> void:
	if debug_individual or Globals.debug:
		_setup_debug_labels()
		for c in get_children():
			if c is Area2D:
				var shape: Node = c.get_child(0)
				if shape is CollisionShape2D:
					shape.visible = true
		_navigation_agent.set_debug_enabled(true)
		_navigation_agent.set_debug_use_custom(true)
		_navigation_agent.set_debug_path_custom_color(Color.MAGENTA)
		_navigation_agent.set_debug_path_custom_point_size(10)
		_navigation_agent.set_debug_path_custom_line_width(4)

	else:
		for c in get_children():
			if c is Area2D:
				var shape: Node = c.get_child(0)
				if shape is CollisionShape2D:
					shape.visible = false


func _physics_process(_delta: float) -> void:
	_handle_debug_drawing()
	_handle_movement()

	if _attackable._is_dying:
		return

	_handle_combat()


func _handle_debug_drawing() -> void:
	if (!debug_individual && !Globals.debug):
		return
	
	if (_debug_label != null and _targeted_enemy != null):
		_debug_label.text = "Target: %s" % [_targeted_enemy.name]
	elif _debug_label != null:
		_debug_label.text = "No Target"

	if _debug_label2 != null:
		_debug_label2.text = _anim_sprite.animation

	if _current_cell != null and debug_individual:
		DebugDraw2d.rect(_current_cell.position)

	if team == enums.e_team.player:
		DebugDraw2d.circle(_navigation_agent.target_position,20, 16, Color.BLACK, 2)


func _handle_combat() -> void:
	if _targeted_enemy == null:
		return

	if _is_attacking:
		_update_sprite_direction(_targeted_enemy.global_position)
		return

	if _should_move_to_enemy(_targeted_enemy):
		order_move(_targeted_enemy.global_position, enums.e_order_type.none, true)


func _handle_movement() -> void:
	if _navigation_agent.is_navigation_finished():
		return

	var next_path_position := _navigation_agent.get_next_path_position()
	var new_velocity       := global_position.direction_to(next_path_position) * movement_speed

	if _navigation_agent.avoidance_enabled:
		_navigation_agent.set_velocity(new_velocity)
	else:
		_on_velocity_computed(new_velocity)

	if not _is_attacking:
		_update_sprite_direction(next_path_position)
	_anim_sprite.animation = _run_animation

#endregion

#region Public Functions
func can_afford_to_build() -> structs.can_afford_response:
	var can_afford = structs.can_afford_response.new()
	for r in cost:
		match r:
			enums.e_resource_type.gold:
				if ResourceManager.gold < cost[r]:
					can_afford.reason = enums.e_cannot_build_reason.insufficient_gold
					break
			enums.e_resource_type.wood:
				if ResourceManager.wood < cost[r]:
					can_afford.reason = enums.e_cannot_build_reason.insufficient_wood
					break
			enums.e_resource_type.meat:
				if ResourceManager.meat < cost[r]:
					can_afford.reason = enums.e_cannot_build_reason.insufficient_meat
					break
			enums.e_resource_type.supply:
				if ResourceManager.supply_cap < cost[r] + ResourceManager.supply:
					can_afford.reason = enums.e_cannot_build_reason.insufficient_supply
					break
	can_afford.result = can_afford.reason == enums.e_cannot_build_reason.none
	return can_afford


func get_attackable() -> Attackable:
	return _attackable


func order_move(in_goal, in_order_type := enums.e_order_type.none, silent := false) -> void:
	_is_idle = false
	if _cell_block._is_blocking_cell:
		_cell_block.unblock_cell()
	if in_order_type != enums.e_order_type.attack:
		_disconnect_signals_on_target_change(_targeted_enemy)
	if in_order_type == enums.e_order_type.move:
		_vision_area.monitoring = false
	if _is_attacking:
		_stop_attacking()
	
	_acknowledge(silent)
	_anim_sprite.animation = _run_animation
	set_movement_target(in_goal)

func order_attack(enemy):
	_disconnect_signals_on_target_change(enemy)
	Util.create_one_shot_audio_stream("attacking_audio_stream", engage_sounds, self)

	if enemy is CharacterBody2D:
		_targeted_enemy = enemy.get_node("Attackable")
	else:
		_targeted_enemy = enemy

	var result: int = _targeted_enemy.sig_dying.connect(_on_target_die)

	if result == ERR_INVALID_PARAMETER:
		push_error("Invalid parameter!")

	if (_attack_area.overlaps_area(_targeted_enemy.get_collision_area())):
		_begin_attacking()
	else:
		order_move(enemy.global_position, enums.e_order_type.attack, true)

func set_in_selection(val):
	_attackable.set_in_selection(val)

func stop_moving() -> void:
	set_movement_target(position)

func set_movement_target(movement_target: Vector2) -> void:
	_navigation_agent.set_target_position(movement_target)

func set_selection_circle_visible(new_visible) -> void:
	$"Selection Circle".visible = new_visible
#endregion

#region Private Functions
func _acknowledge(silent: bool) -> void:
	var acknowledger = UnitManager.group_get_acknowledger(_group_guid)
	if !silent and acknowledger == null or acknowledger == self:
		var temp_stream = AudioStreamPlayer2D.new()
		temp_stream.max_distance = Globals.max_audio_stream_distance
		temp_stream.stream = confirm_acks[randi_range(0, len(confirm_acks) - 1)]
		_audio_streams.push_back(temp_stream)
		add_child(temp_stream)
		temp_stream.play()
		if _group_guid != null:
			UnitManager.group_set_acknowledger(_group_guid, self)


func _begin_attacking() -> void:
	stop_moving()
	await _navigation_agent.navigation_finished
	_is_attacking = true
	var animation_name: StringName = _select_attack_animation()
	if _anim_sprite.sprite_frames.has_animation(animation_name):
		_anim_sprite.animation = animation_name


## This assumes a lot and is not very useful in any other situation.
func _can_attack_body(body) -> bool:
	return (_is_idle and
			body is CharacterBody2D and 
			"team" in body and
			(body.team != team and body.team != enums.e_team.neutral) and can_attack_things)


func _check_vision_for_enemy_to_attack() -> void:
	for body in _vision_area.get_overlapping_bodies():
		if (_can_attack_body(body)):
			order_attack(body)
			return


func _disconnect_signals_on_target_change(enemy) -> void:
	if _targeted_enemy == null:
		return

	if _targeted_enemy.sig_dying.is_connected(_on_target_die):
		_targeted_enemy.sig_dying.disconnect(_on_target_die)



func _should_move_to_enemy(enemy: Attackable) -> bool:
	return enemy != null \
	and _vision_area.overlaps_area(enemy.get_collision_area()) \
	and !_is_attacking


func _update_sprite_direction(target_position: Vector2) -> void:
	var is_facing_left := global_position.direction_to(target_position).dot(Vector2.RIGHT) < 0
	_anim_sprite.flip_h = is_facing_left


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


func _find_close_in_group_units_and_stop_them() -> void:
	for a in $SearchAreaSmall.get_overlapping_areas():
		if a.owner == null:
			continue
		if a.owner.is_in_group(Globals.unit_group):
			var unit: Unit = a.owner as Unit
			if UnitManager.groups.has(_group_guid) and unit._group_guid == _group_guid:
				unit.stop()
	UnitManager.groups[_group_guid].group_stopping = false


func _select_attack_animation() -> StringName:
	if len(attack_animations["up"]) == 0 or _targeted_enemy == null:
		return &""
	
	var attack_animation := &""
	var _unit_to_enemy   =  global_position.direction_to(_targeted_enemy.global_position)
	var _up_dot_unit_to_enemy = _unit_to_enemy.dot(Vector2.UP)
	var _right_dot_unit_to_enemy = _unit_to_enemy.dot(Vector2.RIGHT)
	
	# up or down takes over
	if abs(_up_dot_unit_to_enemy) > abs(_right_dot_unit_to_enemy):
		if _up_dot_unit_to_enemy > 0:
			attack_animation = attack_animations["up"][0]
		else:
			attack_animation = attack_animations["down"][0]
	else:
		attack_animation = attack_animations["front"][0]
		if _right_dot_unit_to_enemy > 0:
			_anim_sprite.flip_h = false
		else:
			_anim_sprite.flip_h = true
	
	return attack_animation



func _stop_attacking(keep_target: bool = false) -> void:
	if !keep_target:
		_targeted_enemy = null
	_is_attacking = false
	_attack_timer.stop()
	_anim_sprite.animation = "idle"
#endregion

#region Listeners
func _on_anim_frame_changed() -> void:
	if !_is_attacking:
		return
	
	#check when we are rearing back if the target is dead
	if _anim_sprite.frame < _strike_frame_index:
		if _targeted_enemy == null or _targeted_enemy.is_queued_for_deletion():
			_stop_attacking()
	elif _anim_sprite.frame == _strike_frame_index:
		_on_attack()


func _on_attack_area_body_entered(body: Node2D) -> void:
	if  !body.has_node("Attackable") or body.team == team:
		#print("cannot attack them though")
		return
	_begin_attacking()


func _on_attack_area_body_exited(body: Node2D) -> void:
	var unit: Unit = body as Unit
	if unit == null:
		return

	if unit.get_attackable() != _targeted_enemy or _targeted_enemy == null or _attackable.get_is_dying():
		return

	var target_cache: Attackable = _targeted_enemy
	_stop_attacking(true)


func _on_attack() -> void:
	_weapon_audio_stream.stream = weapon_sounds[randi_range(0, weapon_sounds.size() - 1)]
	_weapon_audio_stream.play()
	assert(_targeted_enemy != null)
	_targeted_enemy.take_damage(damage)



func _on_mouse_overlap() -> void:
	SelectionHandler.mouse_hovered_unit = self #TODO: stop directly setting this



func _on_mouse_exit() -> void:
	if SelectionHandler.mouse_hovered_unit == self:
		SelectionHandler.mouse_hovered_unit = null



func _on_navigation_finished() -> void:
	_vision_area.monitoring = true
	_cell_block.block_cell()
	_is_idle = true
	_anim_sprite.animation = "idle"
	if _targeted_enemy == null and _auto_attack:
		_check_vision_for_enemy_to_attack()



func _on_target_die(target) -> void:
	assert (target == _targeted_enemy)
	_targeted_enemy.sig_dying.disconnect(_on_target_die)
	_stop_attacking()



func _on_vision_area_body_entered(body) -> void:
	if _can_attack_body(body) and _auto_attack:
		order_attack(body)



func _on_vision_area_body_exited(body) -> void:
	if body == _targeted_enemy:
		assert(!(self is Worker))
		_stop_attacking()
		_check_vision_for_enemy_to_attack()



func _on_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
	move_and_slide()
#endregion

#region Setup
func _setup_attack() -> void:
	for anim_name in _anim_sprite.sprite_frames.get_animation_names():
		if Globals.has_pattern("down.*attack", anim_name):
			attack_animations["down"].append(anim_name)
		elif Globals.has_pattern("front.*attack", anim_name):
			attack_animations["front"].append(anim_name)
		elif Globals.has_pattern("up.*attack", anim_name):
			attack_animations["up"].append(anim_name)
	
	# setup attack area collision shape radius
	var attack_area_collision_shape = _attack_area.get_child(0) 
	attack_area_collision_shape.shape.radius = attack_range
	
	_attack_timer = Timer.new()
	_attack_timer.wait_time = attack_cooldown
	_attack_timer.timeout.connect(_on_attack)
	add_child(_attack_timer)

func _setup_audio_streams() -> void:
	add_child(_weapon_audio_stream)
	_weapon_audio_stream.max_distance = Globals.max_audio_stream_distance
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
		if (stream != null and !stream.is_queued_for_deletion() and !stream.playing):
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

func _setup_signal_connections() -> void:
	_anim_sprite.frame_changed.connect(_on_anim_frame_changed)
	if _attack_area:
		_attack_area.body_entered.connect(_on_attack_area_body_entered)
		_attack_area.body_exited.connect(_on_attack_area_body_exited)
	_navigation_agent.navigation_finished.connect(_on_navigation_finished)
	_navigation_agent.velocity_computed.connect(Callable(_on_velocity_computed))
	_selection_hover_area.mouse_entered.connect(_on_mouse_overlap)
	_selection_hover_area.mouse_exited.connect(_on_mouse_exit)
	if _vision_area:
		_vision_area.body_entered.connect(_on_vision_area_body_entered)
		_vision_area.body_exited.connect(_on_vision_area_body_exited)

#endregion
