extends CharacterBody2D

@export var movement_speed: float = 4.0

@onready var navigation_agent: NavigationAgent2D = get_node("NavigationAgent2D")

func _ready() -> void:
	add_to_group(Globals.unit_group)
	navigation_agent.velocity_computed.connect(
			Callable(_on_velocity_computed))


func set_movement_target(movement_target: Vector2):
	navigation_agent.set_target_position(movement_target)
	
	
func set_selection_circle_visible(visible):
	$"Selection Circle".visible = visible


func _physics_process(delta: float) -> void:
	# GODOT 4.3 Do not query whent he map has never synchronized and is empty.
	#if NavigationServer2D.map_get_iteration_id(navigation_agent.get_navigation_map()) == 0:
		#return
	if navigation_agent.is_navigation_finished():
		return
		
	var next_path_position: Vector2 = navigation_agent.get_next_path_position()
	var new_velocity: Vector2 = global_position.direction_to(next_path_position) * movement_speed
	
	if navigation_agent.avoidance_enabled:
		navigation_agent.set_velocity(new_velocity)
	else:
		_on_velocity_computed(new_velocity)



func _input(event: InputEvent) -> void:
	#print(event.as_text())
	if event.is_action_pressed("Right Click"):
		set_movement_target(get_global_mouse_position())
		

func _on_velocity_computed(safe_velocity: Vector2):
	velocity = safe_velocity
	move_and_slide()
	

func _spawn():
	pass
