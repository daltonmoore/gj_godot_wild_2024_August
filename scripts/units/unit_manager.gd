extends Node2D

var groups : Dictionary = {}

func delete_group(group_guid) -> void:
	groups.erase(group_guid)

func leave_group(unit) -> void:
	var guid = unit.group_guid
	if groups.has(guid):
		unit.group_guid = null
		groups[guid].units.erase(unit)
		if len(groups[guid].units) == 0:
			print("deleting group %s " % guid)
			delete_group(guid)

func add_group(units) -> int:
	var group = Group.new()
	group.units = units
	group.guid = hash(Time.get_unix_time_from_system())
	groups[group.guid] = group
	# No squads
	#group.squad = Squad.new()
	#group.squad.name = "Squad_" + str(group.guid)
	#get_tree().get_root().add_child(group.squad)
	#group.squad.position = get_group_average_position(group.guid)
	#group.squad.move_to_position(get_global_mouse_position())
	return group.guid

func group_get_acknowledger(guid) -> Unit:
	if groups.has(guid):
		return groups[guid].acknowledger
	return null

func group_set_acknowledger(guid, unit) -> void:
	if groups.has(guid):
		groups[guid].acknowledger = unit
	else:
		push_error("No group with guid %s" % guid)

func get_group_average_position(guid) -> Vector2:
	var summed_vec = Vector2.ZERO
	for unit in groups[guid].units:
		summed_vec += unit.position
	
	return summed_vec / groups[guid].units.size() as Vector2

class Group:
	var squad : Squad
	var guid
	var units
	var acknowledger
	var group_stopping := false
