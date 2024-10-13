class_name Unit
extends CharacterBody2D

@export var movement_speed: float = 4.0

# Public Vars
var current_cell: SelectionGridCell:
	get:
		return current_cell
	set(value):
		current_cell = value

# Private Vars
var _current_cell_label
var _current_order_type : enums.e_order_type

@onready var navigation_agent: NavigationAgent2D = get_node("NavigationAgent2D")

func _ready() -> void:
	# Debug name text
	var label = Label.new()
	label.text = "%s" % name
	add_child(label)
	label.position = Vector2(0, -100) # is relative pos
	
	# debug current cell text
	_current_cell_label = Label.new()
	add_child(_current_cell_label)
	_current_cell_label.position = Vector2(0, 25) # is relative pos
	add_to_group(Globals.unit_group)
	navigation_agent.velocity_computed.connect(Callable(_on_velocity_computed))
	$Area2D.mouse_entered.connect(on_mouse_overlap)
	$Area2D.mouse_exited.connect(on_mouse_exit)
	z_index = Globals.unit_z_index


func set_movement_target(movement_target: Vector2):
	navigation_agent.set_target_position(movement_target)
	
	
func set_selection_circle_visible(visible):
	$"Selection Circle".visible = visible

func _physics_process(delta: float) -> void:
	var next_path_position: Vector2 = navigation_agent.get_next_path_position()
	var new_velocity: Vector2 = global_position.direction_to(next_path_position) * movement_speed
	
	if navigation_agent.avoidance_enabled:
		navigation_agent.set_velocity(new_velocity)
	else:
		_on_velocity_computed(new_velocity)
	
	if new_velocity.dot(Vector2.RIGHT) < 0:
		$AnimatedSprite2D.flip_h = true
	else:
		$AnimatedSprite2D.flip_h = false


func _on_velocity_computed(safe_velocity: Vector2):
	velocity = safe_velocity
	move_and_slide()

func order_move(in_goal, in_order_type : enums.e_order_type):
	set_movement_target(in_goal)

func on_mouse_overlap():
	SelectionHandler.mouse_hovered_unit = self

func on_mouse_exit():
	if SelectionHandler.mouse_hovered_unit == self:
		SelectionHandler.mouse_hovered_unit = null
