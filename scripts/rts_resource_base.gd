class_name RTS_Resource_Base
extends Selectable

signal sig_can_gather(unit)

var resource_type : enums.e_resource_type

func _ready() -> void:
	z_index = Globals.foreground_z_index
	object_type = enums.e_object_type.resource


func _process(delta: float) -> void:
	pass


#TODO: I think AOE2 does this by number of hits maybe? Could just stop the timer if gathering ceases
func gather(unit : Unit) -> bool:
	unit.stop_gathering.connect(_on_unit_stop_gathering)
	
	return true


#TODO: make sure this works for multiple workers
func _on_unit_stop_gathering(unit: Unit) -> void:
	unit.stop_gathering.disconnect(_on_unit_stop_gathering)
