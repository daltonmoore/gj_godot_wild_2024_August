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

signal stop_gathering(unit)

@export var movement_speed: float = 4.0
@export var max_resource_holding := 5

# Public Vars
var current_cell: SelectionGridCell:
	get:
		return current_cell
	set(value):
		current_cell = value

# Private Vars
var _current_cell_label
# just assuming any goal is a resource for now, could eventually be an enemy
var _goal_type : enums.e_resource_type = enums.e_resource_type.none
var _resource_goal : RTS_Resource
var _current_resource_holding := 0
var _holding_resource_bundle := false
var _is_gathering := false
var _wood_bundle_sprite := load("res://scenes/rts_resources/wood.tscn")
var _wood_bundle_instance: AnimatedSprite2D

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
	navigation_agent.navigation_finished.connect(_on_navigation_finished)
	$ResourceGatherTick.timeout.connect(_on_resource_gather_tick_timeout)
	
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
	var next_path_position: Vector2 = navigation_agent.get_next_path_position()
	var new_velocity: Vector2 = global_position.direction_to(next_path_position) * movement_speed
	
	if navigation_agent.avoidance_enabled:
		if new_velocity.dot(Vector2.RIGHT) < 0:
			$AnimatedSprite2D.flip_h = true
			if $ResourceHoldPos.get_child_count() > 0:
				$ResourceHoldPos.get_child(0).flip_h = true
		else:
			$AnimatedSprite2D.flip_h = false
			if $ResourceHoldPos.get_child_count() > 0:
				$ResourceHoldPos.get_child(0).flip_h = false
		navigation_agent.set_velocity(new_velocity)
	else:
		_on_velocity_computed(new_velocity)


func _on_velocity_computed(safe_velocity: Vector2):
	velocity = safe_velocity
	move_and_slide()


func _on_navigation_finished():
	if _goal_type == enums.e_resource_type.wood:
		$AnimatedSprite2D.animation = "chop"
		if _resource_goal != null:
			_is_gathering = true
			_resource_goal.gather(self)
	elif _holding_resource_bundle:
		$AnimatedSprite2D.animation = "idle_holding"
		_set_wood_bundle_anim("idle")
	else:
		$AnimatedSprite2D.animation = "idle"
	


func order_move(goal = get_global_mouse_position(), goal_type = enums.e_resource_type.none):
	set_movement_target(goal)
	_goal_type = goal_type
	
	if (goal_type != enums.e_resource_type.wood and _is_gathering):
		_stop_gathering()
	
	if _holding_resource_bundle:
		$AnimatedSprite2D.animation = "walk_holding"
		_set_wood_bundle_anim("walk")
	else:
		$AnimatedSprite2D.animation = "walk"


func gather_resource(resource: RTS_Resource):
	if _current_resource_holding >= max_resource_holding:
		print("Not gathering anymore because holding max resources already")
		return 
	
	_resource_goal = resource
	#TODO:take dot into account for gatherpos location
	order_move(resource.get_node("GatherPos").global_position, resource.resource_type)
	
	#TODO:when should the unit drop all they are holding?
	#		AOE2 clears it out when they start collecting a different resource
	$ResourceGatherTick.stop()
	$ResourceGatherTick.start()
	
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


func _on_resource_gather_tick_timeout():
	_current_resource_holding += 1
	assert (_current_resource_holding <= max_resource_holding)
	if _current_resource_holding == max_resource_holding:
		_finish_gathering()
		

#TODO:possibly do like one log in the bundle to two logs as we gather to show progress.
func _finish_gathering():
	_handle_resource_bundle()
	$ResourceGatherTick.stop()
	$AnimatedSprite2D.animation = "idle_holding"
	

# not finished but has ceased gathering
func _stop_gathering():
	_is_gathering = false
	_handle_resource_bundle()
	$ResourceGatherTick.stop()
	stop_gathering.emit(self)


func _handle_resource_bundle():
	if _current_resource_holding <= 0:
		return
	
	_holding_resource_bundle = true
	if _wood_bundle_instance != null:
		_wood_bundle_instance.queue_free()
	_wood_bundle_instance = _wood_bundle_sprite.instantiate()
	$ResourceHoldPos.add_child(_wood_bundle_instance)
	_set_wood_bundle_anim("idle")


func _set_wood_bundle_anim(type: String):
	match float(_current_resource_holding) / max_resource_holding:
		0:
			return
		0.1, 0.2, 0.3, 0.4:
			if type == "idle":
				#$ResourceHoldPos.get_child(0).animation = "idle_one_bob"
				_wood_bundle_instance.animation = "idle_one_bob"
			elif type == "walk":
				_wood_bundle_instance.animation = "walking_one_bob"
		0.5, 0.6, 0.7, 0.8:
			_wood_bundle_instance.animation = "idle_two_bob"
		0.9, 1.0:
			_wood_bundle_instance.animation = "idle_three_bob"



