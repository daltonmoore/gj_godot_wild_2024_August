extends CharacterBody2D

@export var movement_speed: float =  100.0

var _is_attacking := false
var _timer_idle_eat_grass : Timer

@onready var _anim_sprite : AnimatedSprite2D = $Sheep/Sprite
@onready var _navigation_agent: NavigationAgent2D = get_node("NavigationAgent2D")

func _ready() -> void:
	_timer_idle_eat_grass = Timer.new()
	_timer_idle_eat_grass.wait_time = 4
	add_child(_timer_idle_eat_grass)
	_timer_idle_eat_grass.timeout.connect(_idle_eat_grass)
	_timer_idle_eat_grass.start()
	InputManager.right_click_pressed.connect(_go_to)
	
func _process(_delta: float) -> void:
	_handle_movement()
	
func _go_to(event) -> void:
	var mouse_pos = get_global_mouse_position()
	_navigation_agent.set_target_position(mouse_pos)
	
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
