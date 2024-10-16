extends Node2D

var groups : Dictionary = {}

func delete_group(group_guid) -> void:
	groups.erase(group_guid)

func leave_group(unit) -> void:
	if groups.has(unit.group_guid):
		groups[unit.group_guid].units.erase(unit)
		if len(groups[unit.group_guid].units) == 0:
			print("deleting group %s " % unit.group_guid)
			delete_group(unit.group_guid)

func add_group(units) -> int:
	var group = Group.new()
	group.units = units
	group.guid = hash(Time.get_unix_time_from_system())
	groups[group.guid] = group
	
	return group.guid

func group_get_acknowledger(guid) -> Unit:
	return groups[guid].acknowledger

func group_set_acknowledger(guid, unit) -> void:
	groups[guid].acknowledger = unit

class Group:
	var guid
	var units
	var acknowledger
	var group_stopping := false
