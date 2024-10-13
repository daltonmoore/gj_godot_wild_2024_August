class_name Worker
extends Unit

signal stop_gathering(unit)

@export var max_resource_holding := 5
@export_range(0.1, 2.0) var collection_rate := 1.1

# just assuming any goal is a resource for now, could eventually be an enemy
var _resource_goal : RTS_Resource_Base
var _current_building
var _current_resource_holding_type := enums.e_resource_type.none
var _current_resource_holding := 0
var _holding_resource_bundle := false
var _is_gathering := false
var _wood_bundle_sprite := load("res://scenes/RTS_Resources/wood.tscn")
var _gold_bundle_sprite := load("res://scenes/RTS_Resources/gold.tscn")
var _bundle_instance: AnimatedSprite2D
var _is_turning_in_resources := false

# for debug resource holding
var woodlabel = Label.new()

func _ready() -> void:
	add_child(woodlabel)
	woodlabel.position = Vector2(0, -20) # is relative pos
	
	navigation_agent.navigation_finished.connect(_on_navigation_finished)
	$ResourceGatherTick.timeout.connect(_on_resource_gather_tick_timeout)
	$ResourceGatherTick.wait_time = collection_rate
	super()

func _process(delta: float) -> void:
	woodlabel.text = "wood: %s" % _current_resource_holding
	# Debug name text
	if current_cell != null:
		_current_cell_label.text = "%s" % current_cell.grid_pos

func _physics_process(delta: float) -> void:
	super(delta)
	if _bundle_instance != null and !_bundle_instance.is_queued_for_deletion():
		_bundle_instance.flip_h = $AnimatedSprite2D.flip_h

func _on_navigation_finished():
	if (_current_order_type == enums.e_order_type.gather
			and _resource_goal != null):
		if _resource_goal.resource_type == enums.e_resource_type.wood:
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
		_set_bundle_anim("idle")
	else:
		$AnimatedSprite2D.animation = "idle"

func _wait_for_can_gather(unit):
	if _resource_goal.gather(self):
		print("Begin gathering")
		_resource_goal.sig_can_gather.disconnect(_wait_for_can_gather)
		_begin_gathering()

func gather_resource(resource: RTS_Resource_Base):
	if _current_resource_holding >= max_resource_holding:
		print("Not gathering anymore because holding max resources already")
		return
	
	# we stop gathering if this is a new resource node
	if resource != _resource_goal and _is_gathering:
		_stop_gathering()
	elif resource == _resource_goal: # if they are the same then we don't care
		return 
		
	_resource_goal = resource
	#TODO:take dot into account for gatherpos location
	order_move(resource.get_node("GatherPos").global_position, enums.e_order_type.gather)
	
	
	#TODO:when should the unit drop all they are holding?
	#		AOE2 clears it out when they start collecting a different resource

func order_move(in_goal, in_order_type : enums.e_order_type):
	_current_order_type = in_order_type
	#TODO: make this a variable instead of magic 5
	if (in_goal.distance_to(position) > 5 and _is_gathering):
		_stop_gathering()
	
	if (in_order_type != enums.e_order_type.build and _current_building != null and
			(navigation_agent.navigation_finished.is_connected(_begin_construction) or
			_current_building.finish_building.is_connected(_on_finish_construction))
		):
		_current_building.finish_building.disconnect(_on_finish_construction)
		_current_building.stop_building()
		_current_building = null
		navigation_agent.navigation_finished.disconnect(_begin_construction)
	
	# clear resource goal if we issue new move order while on the way to gather
	if (in_order_type != enums.e_order_type.gather and _resource_goal != null):
		_resource_goal = null
		if _resource_goal.sig_can_gather.is_connected(_wait_for_can_gather):
			_resource_goal.sig_can_gather.disconnect(_wait_for_can_gather)
	
	if (in_order_type != enums.e_order_type.deposit and
			_is_turning_in_resources and
			navigation_agent.navigation_finished.is_connected(_deposit_resources)):
		navigation_agent.navigation_finished.disconnect(_deposit_resources)
	
	if _holding_resource_bundle:
		$AnimatedSprite2D.animation = "walk_holding"
		_set_bundle_anim("walk")
	else:
		$AnimatedSprite2D.animation = "walk"
	
	super(in_goal, in_order_type)

func order_deposit_resources(building: Building):
	_is_turning_in_resources = true
	navigation_agent.navigation_finished.connect(_deposit_resources)
	order_move(building.position, enums.e_order_type.deposit)


func build(building) -> void:
	print(building)
	_current_building = building
	
	navigation_agent.navigation_finished.connect(_begin_construction)
	order_move(building.get_random_point_along_perimeter(), enums.e_order_type.build)


func _begin_construction() -> void:
	navigation_agent.navigation_finished.disconnect(_begin_construction)
	$AnimatedSprite2D.animation = "mine"
	_current_building.start_building()
	_current_building.finish_building.connect(_on_finish_construction)


func _on_finish_construction() -> void:
	_current_building.finish_building.disconnect(_on_finish_construction)
	_current_building = null
	$AnimatedSprite2D.animation = "idle"


func _deposit_resources():
	Hud.update_resource(_current_resource_holding_type, _current_resource_holding)
	ResourceManager._add_resource(_current_resource_holding, _current_resource_holding_type)
	_current_resource_holding = 0
	_holding_resource_bundle = false
	$AnimatedSprite2D.animation = "idle"
	if _bundle_instance != null:
		_bundle_instance.queue_free()

func _on_resource_gather_tick_timeout():
	_current_resource_holding += 1
	assert (_current_resource_holding <= max_resource_holding)
	if _current_resource_holding == max_resource_holding:
		_stop_gathering()


func _stop_gathering():
	$ResourceGatherTick.stop()
	_is_gathering = false
	_handle_resource_bundle()
	_resource_goal = null
	stop_gathering.emit(self)
	order_deposit_resources(_find_closest_townhall())


func _handle_resource_bundle():
	if _current_resource_holding <= 0:
		return
	
	_holding_resource_bundle = true
	if _bundle_instance != null:
		_bundle_instance.queue_free()
		
	match _resource_goal.resource_type:
		enums.e_resource_type.wood:
			_bundle_instance = _wood_bundle_sprite.instantiate() 
		enums.e_resource_type.gold:
			_bundle_instance = _gold_bundle_sprite.instantiate()
	
	$ResourceHoldPos.add_child(_bundle_instance)
	print("created new bundle")
	_set_bundle_anim("idle")


func _set_bundle_anim(type: String):
	
	if !is_instance_valid(_bundle_instance):
		print("bundle is not valid, returning early")
		return
	
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

func _find_closest_townhall() -> Building:
	var closest_townhall
	for a in  $SearchArea.get_overlapping_areas():
		if a.is_in_group("TurnInPoint"):
			closest_townhall = a.owner
			break
	
	return closest_townhall
