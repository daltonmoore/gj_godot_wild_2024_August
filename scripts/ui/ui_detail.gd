@tool
class_name UiDetail
extends Resource

@export var image: Texture2D = null
@export var ui_detail_type: enums.E_UIDetailType
var _use_detail: bool = false
@export var use_detail: bool:
	get:
		return _use_detail
	set(value):
		_use_detail = value
		notify_property_list_changed()
var detail: float = 0.0

func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []
	properties.append({
		"name": "detail",
		"type": TYPE_FLOAT,
		"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE if use_detail else PROPERTY_USAGE_STORAGE,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0,200"  # Assuming detail should be between 0 and 1
	})
	return properties
