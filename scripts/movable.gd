class_name Movable
extends Unit

var _timer_idle_eat_grass : Timer


func _ready() -> void:
	_anim_sprite = $Sheep/Sprite
	_timer_idle_eat_grass = Timer.new()
	_timer_idle_eat_grass.wait_time = 4
	add_child(_timer_idle_eat_grass)
	_timer_idle_eat_grass.timeout.connect(_idle_eat_grass)
	_timer_idle_eat_grass.start()
	
	_setup_audio_streams()
	_setup_signal_connections()
	
func _process(_delta: float) -> void:
	_handle_movement()
	
# this is lifted from the Unit script. Could possibly move this to some kind of interface or have Unit inherit from Movable
func order_move(in_goal, _in_order_type := enums.e_order_type.none, _silent := false) -> void:
	if _cell_block._is_blocking_cell:
		_cell_block.unblock_cell()

	_anim_sprite.animation = "move"
	set_movement_target(in_goal)

func set_selection_circle_visible(new_visible) -> void:
	$"Sheep/Selection Circle".visible = new_visible

func set_in_selection(val):
	_attackable.set_in_selection(val)
	
func set_movement_target(movement_target: Vector2) -> void:
	_navigation_agent.set_target_position(movement_target)
	
	
func _handle_movement() -> void:
	if _navigation_agent.is_navigation_finished():
		if _timer_idle_eat_grass.is_stopped():
			_anim_sprite.play("idle")
			_timer_idle_eat_grass.start()
		return
	_timer_idle_eat_grass.stop()
	var next_path_position := _navigation_agent.get_next_path_position()
	var new_velocity       := global_position.direction_to(next_path_position) * movement_speed

	if _navigation_agent.avoidance_enabled:
		_navigation_agent.set_velocity(new_velocity)
	else:
		_on_velocity_computed(new_velocity)
	_anim_sprite.play("move")
	#if not _is_attacking:
	_update_sprite_direction(next_path_position)
	#_anim_sprite.animation = "run"


func _on_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
	move_and_slide()


func _update_sprite_direction(target_position: Vector2) -> void:
	var is_facing_left := global_position.direction_to(target_position).dot(Vector2.RIGHT) < 0
	_anim_sprite.flip_h = is_facing_left

	
func _idle_eat_grass():
	if _anim_sprite.animation == "eat grass":
		_anim_sprite.play("idle")
	elif _anim_sprite.animation == "idle":
		_anim_sprite.play("eat grass")
