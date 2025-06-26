class_name Worker
extends Unit

#region Signals
signal path_changed(path)
signal stop_gathering(unit)
#endregion

#region Exports
@export_range(0.1, 2.0) var collection_rate := 1.1
@export var max_resource_holding := 5
#endregion

#region Private Vars
# is the worker automatically turning after gathering?
# used to discern when the player orders the turn in or it happens automatically
var _auto_gather := false
var _bundle_instance: AnimatedSprite2D
# just assuming any goal is a resource for now, could eventually be an enemy
var _current_building
var _current_resource_holding_type := enums.e_resource_type.none
var _current_resource_holding := 0
var _current_resource_type := enums.e_resource_type.none
var _holding_resource_bundle := false
var _gold_bundle_sprite := load("res://scenes/gathered_resources/gold.tscn")
var _is_gathering := false
var _is_turning_in_resources := false
var _resource_goal : RTS_Resource_Base
var _wood_bundle_sprite := load("res://scenes/gathered_resources/wood.tscn")
#endregion

#region Debug Vars
# for debug resource holding
var auto_label = Label.new()
var deposit_label = Label.new()
var going_to_new_resource_label = Label.new()
var wood_label = Label.new()
#endregion

func _ready() -> void:
	super()
	_auto_attack = false
	add_child(wood_label)

	if debug_individual:
		add_child(deposit_label)
		add_child(auto_label)
		add_child(going_to_new_resource_label)
		auto_label.position = Vector2(20, -60)
		deposit_label.position = Vector2(20, -40)
		going_to_new_resource_label.position = Vector2(20, -80)
		wood_label.position = Vector2(0, -20) # is relative pos
	
	$ResourceGatherTick.timeout.connect(_on_resource_gather_tick_timeout)
	$ResourceGatherTick.wait_time = 1/collection_rate

func _process(_delta: float) -> void:
	#auto_label.text = "auto_gather?: %s" % _auto_gather
	wood_label.text = "wood: %s" % _current_resource_holding
	# Debug name text
	if debug_individual:
		if _current_cell != null:
			_current_cell_label.text = "%s" % _current_cell.grid_pos
		else:
			_current_cell_label.text = "none cell"
	
	if _anim_sprite.animation == "chop":
		if !$WoodChop.playing:
			$WoodChop.play()
	elif $WoodChop.playing:
		$WoodChop.stop()

func _physics_process(delta: float) -> void:
	super(delta)
	if _bundle_instance != null and !_bundle_instance.is_queued_for_deletion():
		_bundle_instance.flip_h = _anim_sprite.flip_h

func order_move(in_goal, in_order_type := enums.e_order_type.none, silent := false):
	super(in_goal, in_order_type, silent)
	#print(enums.e_order_type.keys()[in_order_type])
	_current_order_type = in_order_type
	
	if in_order_type == enums.e_order_type.move:
		_auto_gather = false
	
	#TODO: make this a variable instead of magic 5
	if (in_goal.distance_to(position) > 5 and _is_gathering):
		_stop_gathering()
	
	#TODO: this is difficult to understand
	if (in_order_type != enums.e_order_type.build and _current_building != null and
			(_navigation_agent.navigation_finished.is_connected(_begin_construction) or
			_current_building.finish_building.is_connected(_on_finish_construction))
		):
		_current_building.finish_building.disconnect(_on_finish_construction)
		_current_building.stop_building()
		_current_building = null
		_navigation_agent.navigation_finished.disconnect(_begin_construction)
	
	# clear resource goal if we issue new move order while on the way to gather
	if (in_order_type != enums.e_order_type.gather and _resource_goal != null and !_auto_gather):
		if _resource_goal.sig_can_gather.is_connected(_wait_for_can_gather):
			_resource_goal.sig_can_gather.disconnect(_wait_for_can_gather)
		_resource_goal = null
		
	
	if (in_order_type != enums.e_order_type.deposit and
			_is_turning_in_resources and
			_navigation_agent.navigation_finished.is_connected(_deposit_resources)):
		print("Disconnecting Deposit Resources from navigation finished")
		_navigation_agent.navigation_finished.disconnect(_deposit_resources)
	
	if _holding_resource_bundle:
		_set_bundle_anim("run")

func order_deposit_resources(building: Building):
	_is_turning_in_resources = true
	if !_navigation_agent.navigation_finished.is_connected(_deposit_resources):
		_navigation_agent.navigation_finished.connect(_deposit_resources)
	order_move(building.get_random_point_along_perimeter(position), enums.e_order_type.deposit, _auto_gather)

func order_gather_resource(resource: RTS_Resource_Base):
	if _current_resource_holding >= max_resource_holding:
		#print("Not gathering anymore because holding max resources already")
		return
	
	# we stop gathering if this is a new resource node
	if resource != _resource_goal and _is_gathering:
		_stop_gathering(true)
	elif !_auto_gather and resource == _resource_goal: # if they are the same then we don't care
		return 
		
	_resource_goal = resource
	if !resource.exhausted.is_connected(_on_resource_exhausted):
		resource.exhausted.connect(_on_resource_exhausted)
	_current_resource_type = resource.resource_type
	#TODO:take dot into account for gatherpos location
	order_move(resource.get_random_gather_point(), enums.e_order_type.gather, _auto_gather)
	
	
	#TODO:when should the unit drop all they are holding?
	#		AOE2 clears it out when they start collecting a different resource

func build(building) -> void:
	#print(building)
	_current_building = building
	
	_navigation_agent.navigation_finished.connect(_begin_construction)
	order_move(building.get_random_point_along_perimeter(position), enums.e_order_type.build)

func _on_navigation_finished() -> void:
	super()
	emit_signal("path_changed", [])
	if (_current_order_type == enums.e_order_type.gather
			and _resource_goal != null):
		if _resource_goal.resource_type == enums.e_resource_type.wood:
			_anim_sprite.animation = "chop"
		assert ($ResourceGatherTick.is_stopped())
		var b_can_gather = _resource_goal.gather(self)
		
		if !b_can_gather:
			_anim_sprite.animation = "idle"
			assert(_resource_goal.sig_can_gather.is_connected(_wait_for_can_gather) == false)
			_resource_goal.sig_can_gather.connect(_wait_for_can_gather)
		else:
			_begin_gathering()
	elif _holding_resource_bundle:
		_anim_sprite.animation = "idle_holding"
		_set_bundle_anim("idle")
	else:
		_anim_sprite.animation = "idle"

func _wait_for_can_gather(unit):
	if _resource_goal.gather(self):
		_resource_goal.sig_can_gather.disconnect(_wait_for_can_gather)
		_begin_gathering()

func _begin_construction() -> void:
	_navigation_agent.navigation_finished.disconnect(_begin_construction)
	_anim_sprite.animation = "mine"
	_current_building.start_building()
	_current_building.finish_building.connect(_on_finish_construction)

func _on_finish_construction() -> void:
	_current_building.finish_building.disconnect(_on_finish_construction)
	_current_building = null
	_anim_sprite.animation = "idle"

func _on_resource_exhausted() -> void:
	_stop_gathering(false, true)
	var closest_resource = _find_next_closest_resource()
	if closest_resource != null:
		order_gather_resource(closest_resource)
	else:
		_anim_sprite.animation = "idle"

func _deposit_resources():
	ResourceManager._update_resource(_current_resource_holding, _current_resource_holding_type)
	_current_resource_holding = 0
	_holding_resource_bundle = false
	_anim_sprite.animation = "idle"
	if _bundle_instance != null:
		_bundle_instance.queue_free()
	
	if _auto_gather:
		if _resource_goal != null:
			order_gather_resource(_resource_goal)
		else:
			var closest_resource = _find_next_closest_resource()
			#print("Resource Goal is Null! finding closest resource")
			if closest_resource != null:
				order_gather_resource(closest_resource)

func _on_resource_gather_tick_timeout():
	if _resource_goal == null:
		_stop_gathering(true, true)
		var closest_resource = _find_next_closest_resource()
		if closest_resource != null:
			order_gather_resource(closest_resource)
		return
	_current_resource_holding += _resource_goal.take(1)
	assert (_current_resource_holding <= max_resource_holding)
	if _current_resource_holding == max_resource_holding:
		_stop_gathering(false, true, true)

func _begin_gathering():
	$ResourceGatherTick.start()
	_is_gathering = true

func _stop_gathering(going_to_new_resource:= false, auto_gather:= false, deposit := false):
	deposit_label.text = "deposit?: %s" % deposit
	going_to_new_resource_label.text = "going_to_new_resource?: %s" % going_to_new_resource
	
	$ResourceGatherTick.stop()
	_auto_gather = auto_gather
	_is_gathering = false
	_handle_resource_bundle()
	stop_gathering.emit(self)
	
	if deposit:
		_resource_goal.exhausted.disconnect(_on_resource_exhausted)
		order_deposit_resources(_find_closest_townhall())
	# only clear resource_goal if we are going to a new one, want to keep for auto gather
	if going_to_new_resource:
		_resource_goal = null

func _handle_resource_bundle():
	if _current_resource_holding <= 0:
		return
	
	_holding_resource_bundle = true
	if _bundle_instance != null:
		_bundle_instance.queue_free()
	
	_current_resource_holding_type = _current_resource_type
	
	match _current_resource_type:
		enums.e_resource_type.wood:
			_bundle_instance = _wood_bundle_sprite.instantiate() 
		enums.e_resource_type.gold:
			_bundle_instance = _gold_bundle_sprite.instantiate()
	
	$ResourceHoldPos.add_child(_bundle_instance)
	_set_bundle_anim("idle")

func _set_bundle_anim(type: String):
	
	if !is_instance_valid(_bundle_instance):
		#print("bundle is not valid, returning early")
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
		_anim_sprite.animation = "idle_holding"
		_bundle_instance.animation = "idle_"+amt+"_bob"
	elif type == "run":
		_anim_sprite.animation = "run_holding"
		_bundle_instance.animation = "walking_"+amt+"_bob"

func _find_closest_townhall() -> Building:
	var cloest_townhall = _find_closest_thing("TurnInPoint")
	return cloest_townhall as Building

func _find_next_closest_resource() -> RTS_Resource_Base:
	#assert (_resource_goal.resource_amount == 0)
	var closest_resource = _find_closest_thing("Resource", _resource_goal, _current_resource_type)
	return closest_resource as RTS_Resource_Base

func _find_closest_thing(thing : String, ignore = null, filter = null) -> Node2D:
	var closest_thing
	var closest_pos = Vector2(10000, 10000)
	for a in $SearchAreaSmall.get_overlapping_areas():
		print (a.owner)
		if ignore != null and ignore == a.owner:
			continue
		if a.is_in_group(thing):
			if filter != null:
				var res = a.owner as RTS_Resource_Base
				if res != null:
					if res.resource_type != filter:
						continue
			#print("found closest thing = %s" % a.owner.name)
			if position.distance_to(a.owner.position) < position.distance_to(closest_pos):
				closest_thing = a.owner
				closest_pos = a.owner.position
	
	if closest_thing == null:
		for a in $SearchAreaLarge.get_overlapping_areas():
			if ignore != null and ignore == a.owner:
				continue
			if (a.is_in_group(thing) and 
					(filter == null or (filter != null and is_instance_of(a.owner, filter)))
				):
				print(a.owner.name)
				if position.distance_to(a.owner.position) < position.distance_to(closest_pos):
					closest_thing = a.owner
					closest_pos = a.owner.position
	
	return closest_thing
