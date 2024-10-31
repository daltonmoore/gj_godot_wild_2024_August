class_name Squad
extends CharacterBody2D

@export var movement_speed: float = 150

var nav_agent : NavigationAgent2D

func _ready() -> void:
	nav_agent = NavigationAgent2D.new()
	nav_agent.navigation_finished.connect(_on_navigation_finished)
	nav_agent.velocity_computed.connect(Callable(_on_velocity_computed))
	add_child(nav_agent)
	
	var sprite = Sprite2D.new()
	sprite.texture = load("res://art/ui/Square.png")
	add_child(sprite)
	
	var collision_shape = CollisionShape2D.new()
	collision_shape.shape = CircleShape2D.new()
	add_child(collision_shape)

func _physics_process(_delta: float) -> void:
	var next_path_position: Vector2 = nav_agent.get_next_path_position()
	var new_velocity: Vector2 = global_position.direction_to(next_path_position) * movement_speed
	
	if nav_agent.avoidance_enabled:
		nav_agent.set_velocity(new_velocity)
	elif !nav_agent.is_navigation_finished():
		_on_velocity_computed(new_velocity)

func move_to_position(pos) -> void:
	nav_agent.set_target_position(pos)

func _on_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
	move_and_slide()

func _on_navigation_finished() -> void:
	print("Squad nav finished")
