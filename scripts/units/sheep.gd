class_name Sheep
extends Unit

var _timer_idle_eat_grass : Timer


func _ready() -> void:
	_anim_sprite = $Sprite
	z_index = Globals.default_z_index
	
	_timer_idle_eat_grass = Timer.new()
	_timer_idle_eat_grass.wait_time = 4
	add_child(_timer_idle_eat_grass)
	_timer_idle_eat_grass.timeout.connect(_idle_eat_grass)
	_timer_idle_eat_grass.start()

	_run_animation = "move"

	_setup_attack()
	_setup_audio_streams()
	_setup_signal_connections()
	_setup_debug()

	await get_tree().process_frame
	_cell_block.block_cell()

	
func _handle_movement() -> void:
	if _navigation_agent.is_navigation_finished():
		if _timer_idle_eat_grass.is_stopped():
			_anim_sprite.play("idle")
			_timer_idle_eat_grass.start()
		return
	_timer_idle_eat_grass.stop()
	
	super()

	
func _idle_eat_grass():
	if _anim_sprite.animation == "eat grass":
		_anim_sprite.play("idle")
	elif _anim_sprite.animation == "idle":
		_anim_sprite.play("eat grass")
