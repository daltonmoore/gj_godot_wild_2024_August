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

var _current_cell_label
var _goal_type = null

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
	navigation_agent.velocity_computed.connect(
			Callable(_on_velocity_computed))
	
	$Area2D.mouse_entered.connect(on_mouse_overlap)
	$Area2D.mouse_exited.connect(on_mouse_exit)
	
	z_index = Globals.unit_z_index


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
	#TODO: determine animation based on state of unit
	#TODO: face velocity
	if navigation_agent.is_navigation_finished():
		if _goal_type == enums.e_resource_type.wood:
			$AnimatedSprite2D.animation = "chop"
		else:
			$AnimatedSprite2D.animation = "idle"
		return
		
	var next_path_position: Vector2 = navigation_agent.get_next_path_position()
	var new_velocity: Vector2 = global_position.direction_to(next_path_position) * movement_speed
	
	if navigation_agent.avoidance_enabled:
		if new_velocity.dot(Vector2.RIGHT) < 0:
			$AnimatedSprite2D.flip_h = true
		else:
			$AnimatedSprite2D.flip_h = false
		navigation_agent.set_velocity(new_velocity)
	else:
		_on_velocity_computed(new_velocity)


func _on_velocity_computed(safe_velocity: Vector2):
	velocity = safe_velocity
	move_and_slide()


func _spawn():
	pass


func order_move(has_goal = false, goal = get_global_mouse_position()):
	set_movement_target(goal)
	if !has_goal:
		_goal_type = null
	$AnimatedSprite2D.animation = "walk"


func gather_resource(resource_pos):
	#var resource_tile_data = GlobalTileMap.get_cell_tile_data(
			#Globals.tile_map_layer_foreground, resource_tile_pos)
	#var resource_type = resource_tile_data.get_custom_data(
			#Globals.tile_map_custom_data_layer_type)
	var resource = CursorManager.current_hovered_resource
	_goal_type = resource.resource_type
	order_move(true, resource_pos)
	
	# play some gather animation once arrived at resource
	# start a collection timer
	# slowly amass resource
	# reach carrying capacity
	# bring resource to town center


func on_mouse_overlap():
	SelectionHandler.mouse_hovered_unit = self


func on_mouse_exit():
	if SelectionHandler.mouse_hovered_unit == self:
		SelectionHandler.mouse_hovered_unit = null
