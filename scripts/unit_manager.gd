extends Node2D

var group_stopping : bool = false
var groups : Dictionary = {}

func delete_group(group_guid) -> void:
	groups.erase(group_guid)

func leave_group(unit) -> void:
	if groups.has(unit.group_guid):
		groups[unit.group_guid].erase(unit)
		if len(groups[unit.group_guid]) == 0:
			print("deleting group %s " % unit.group_guid)
			delete_group(unit.group_guid)
