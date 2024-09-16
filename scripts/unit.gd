#01. @tool
#02. class_name
#03. extends
#04. # docstring
#
#05. signals
#06. enums
#07. constants
#08. @export variables
#09. public variables
#10. private variables
#11. @onready variables
#
#12. optional built-in virtual _init method
#13. optional built-in virtual _enter_tree() method
#14. built-in virtual _ready method
#15. remaining built-in virtual methods
#16. public methods
#17. private methods
#18. subclasses
class_name Unit
extends CharacterBody2D

@export var movement_speed: float = 4.0
var current_cell: SelectionGridCell:
	get:
		return current_cell
	set(value):
		current_cell = value
@onready var navigation_agent: NavigationAgent2D = get_node("NavigationAgent2D")

var _selection_handler
var _current_cell_label

func _ready() -> void:
	# Debug name text
	var label = Label.new()
	label.text = "%s" % name
	add_child(label)
	label.position = Vector2(0, -50) # is relative pos
	
	# debug current cell text
	_current_cell_label = Label.new()
	add_child(_current_cell_label)
	_current_cell_label.position = Vector2(0, 50) # is relative pos	
	
	add_to_group(Globals.unit_group)
	navigation_agent.velocity_computed.connect(
			Callable(_on_velocity_computed))
	
	$Area2D.mouse_entered.connect(on_mouse_overlap)
	$Area2D.mouse_exited.connect(on_mouse_exit)
	
	_selection_handler = get_node("/root/main/SelectionHandler")


func set_movement_target(movement_target: Vector2):
	navigation_agent.set_target_position(movement_target)
	
	
func set_selection_circle_visible(visible):
	$"Selection Circle".visible = visible




func _process(delta: float) -> void:
	# Debug name text
	if current_cell != null:
		_current_cell_label.text = "%s" % current_cell.grid_pos


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


func _on_velocity_computed(safe_velocity: Vector2):
	velocity = safe_velocity
	move_and_slide()


func _spawn():
	pass


func order_move():
	set_movement_target(get_global_mouse_position())


func on_mouse_overlap():
	_selection_handler.mouse_hovered_unit = self

func on_mouse_exit():
	if _selection_handler.mouse_hovered_unit == self:
		_selection_handler.mouse_hovered_unit = null
