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
@export_range(0.1, 2.0) var collection_rate := 1.1

# Public Vars
var current_cell: SelectionGridCell:
	get:
		return current_cell
	set(value):
		current_cell = value


# Private Vars
var _current_cell_label
# just assuming any goal is a resource for now, could eventually be an enemy
var _resource_goal_type : enums.e_resource_type = enums.e_resource_type.none
var _resource_goal : RTS_Resource_Base
var _current_resource_holding := 0
var _holding_resource_bundle := false
var _is_gathering := false
var _wood_bundle_sprite := load("res://scenes/RTS_Resources/wood.tscn")
var _gold_bundle_sprite := load("res://scenes/RTS_Resources/gold.tscn")
var _bundle_instance: AnimatedSprite2D
var _is_turning_in_resources := false
# for debug resource holding
var woodlabel = Label.new()

@onready var navigation_agent: NavigationAgent2D = get_node("NavigationAgent2D")


func _ready() -> void:
	# Debug name text
	var label = Label.new()
	label.text = "%s" % name
	add_child(label)
	label.position = Vector2(0, -100) # is relative pos
	
	add_child(woodlabel)
	woodlabel.position = Vector2(0, -20) # is relative pos
	
	# debug current cell text
	_current_cell_label = Label.new()
	add_child(_current_cell_label)
	_current_cell_label.position = Vector2(0, 25) # is relative pos
	
	add_to_group(Globals.unit_group)
	
	navigation_agent.velocity_computed.connect(Callable(_on_velocity_computed))
	navigation_agent.navigation_finished.connect(_on_navigation_finished)
	$Area2D.mouse_entered.connect(on_mouse_overlap)
	$Area2D.mouse_exited.connect(on_mouse_exit)
	$ResourceGatherTick.timeout.connect(_on_resource_gather_tick_timeout)
	
	$ResourceGatherTick.wait_time = collection_rate
	
	z_index = Globals.unit_z_index


func set_movement_target(movement_target: Vector2):
	navigation_agent.set_target_position(movement_target)
	
	
func set_selection_circle_visible(visible):
	$"Selection Circle".visible = visible


func _process(delta: float) -> void:
	woodlabel.text = "wood: %s" % _current_resource_holding
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
	if (_resource_goal_type != enums.e_resource_type.none
			and _resource_goal != null):
		if _resource_goal_type == enums.e_resource_type.wood:
			$AnimatedSprite2D.animation = "chop"
		assert ($ResourceGatherTick.is_stopped())
		var b_can_gather = _resource_goal.gather(self)
		
		if !b_can_gather:
			$AnimatedSprite2D.animation = "idle"
			assert(_resource_goal.sig_can_gather.is_connected(_wait_for_can_gather) == false)
			_resource_goal.sig_can_gather.connect(_wait_for_can_gather)
		else:
			print("Begin gathering")
			_begin_gathering()
	elif _holding_resource_bundle:
		$AnimatedSprite2D.animation = "idle_holding"
		_set_wood_bundle_anim("idle")
	else:
		$AnimatedSprite2D.animation = "idle"


func _wait_for_can_gather(unit):
	if _resource_goal.gather(self):
		print("Begin gathering")
		_resource_goal.sig_can_gather.disconnect(_wait_for_can_gather)
		_begin_gathering()


func order_move(object_goal_type := enums.e_object_type.none,
			goal := get_global_mouse_position(), 
			resource_goal_type := enums.e_resource_type.none):
	
	#TODO: make this a variable instead of magic 5
	if (goal.distance_to(position) > 5 and _is_gathering):
		_stop_gathering()
		
	set_movement_target(goal)
	_resource_goal_type = resource_goal_type
	
	if object_goal_type == enums.e_object_type.none and _resource_goal != null:
		_resource_goal.sig_can_gather.disconnect(_wait_for_can_gather)
	
	if _holding_resource_bundle:
		$AnimatedSprite2D.animation = "walk_holding"
		_set_wood_bundle_anim("walk")
	else:
		$AnimatedSprite2D.animation = "walk"


func gather_resource(resource: RTS_Resource_Base):
	if _current_resource_holding >= max_resource_holding:
		print("Not gathering anymore because holding max resources already")
		return
	
	# we stop gathering if this is a new resource node
	if resource != _resource_goal:
		_stop_gathering()
	else: # if they are the same then we don't care
		return 
		
	_resource_goal = resource
	#TODO:take dot into account for gatherpos location
	order_move(enums.e_object_type.resource,
				resource.get_node("GatherPos").global_position,
				resource.resource_type)
	
	
	#TODO:when should the unit drop all they are holding?
	#		AOE2 clears it out when they start collecting a different resource


func order_deposit_resources(building: Building):
	_is_turning_in_resources = true
	#navigation_agent.navigation_finished.connect(_deposit_resources)
	order_move(enums.e_object_type.building)


func on_mouse_overlap():
	SelectionHandler.mouse_hovered_unit = self


func on_mouse_exit():
	if SelectionHandler.mouse_hovered_unit == self:
		SelectionHandler.mouse_hovered_unit = null


func _on_resource_gather_tick_timeout():
	_current_resource_holding += 1
	assert (_current_resource_holding <= max_resource_holding)
	if _current_resource_holding == max_resource_holding:
		_stop_gathering()


func _stop_gathering():
	$ResourceGatherTick.stop()
	_is_gathering = false
	_resource_goal = null
	_handle_resource_bundle()
	stop_gathering.emit(self)


func _handle_resource_bundle():
	if _current_resource_holding <= 0:
		return
	
	_holding_resource_bundle = true
	if _bundle_instance != null:
		_bundle_instance.queue_free()
		
	match _resource_goal_type:
		enums.e_resource_type.wood:
			_bundle_instance = _wood_bundle_sprite.instantiate()
		enums.e_resource_type.gold:
			_bundle_instance = _gold_bundle_sprite.instantiate()
	$ResourceHoldPos.add_child(_bundle_instance)
	_set_wood_bundle_anim("idle")


func _deposit_resources():
	Hud.update_wood(_current_resource_holding)
	_current_resource_holding = 0
	_holding_resource_bundle = false
	$AnimatedSprite2D.animation = "idle"
	if _bundle_instance != null:
		_bundle_instance.queue_free()


func _set_wood_bundle_anim(type: String):
	var amt
	match float(_current_resource_holding) / max_resource_holding:
		0:
			return
		0.1, 0.2, 0.3, 0.4:
			amt = "one"
		0.5, 0.6, 0.7, 0.8:
			amt = "two"
		0.9, 1.0:
			amt = "three"
	
	if type == "idle":
		$AnimatedSprite2D.animation = "idle_holding"
		_bundle_instance.animation = "idle_"+amt+"_bob"
	elif type == "walk":
		$AnimatedSprite2D.animation = "walk_holding"
		_bundle_instance.animation = "walking_"+amt+"_bob"


func _begin_gathering():
	$ResourceGatherTick.start()
	_is_gathering = true

