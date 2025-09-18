@tool
class_name UiDetail
extends Resource

@export var image: Texture2D = null

var _ui_detail_type: enums.E_UIDetailType
@export var ui_detail_type: enums.E_UIDetailType:
	get:
		return _ui_detail_type
	set(value):
		_ui_detail_type = value
		notify_property_list_changed()

var _use_detail: bool = false
@export var use_detail: bool:
	get:
		return _use_detail
	set(value):
		_use_detail = value
		notify_property_list_changed()

var detail: float = 0.0
var texture_normal: Texture2D
var texture_pressed: Texture2D
var texture_hovered: Texture2D

func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []
	properties.append({
		"name": "detail",
		"type": TYPE_FLOAT,
		"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE if use_detail else PROPERTY_USAGE_STORAGE,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0,200"
	})
	
	properties.append({
		"name": "texture_normal",
		"type": TYPE_OBJECT,
		"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE if ui_detail_type == enums.E_UIDetailType.DEBUG_BUTTON else PROPERTY_USAGE_STORAGE,
		"hint": PROPERTY_HINT_RESOURCE_TYPE,
		"hint_string": "Texture2D"
	})
	
	properties.append({
		"name": "texture_pressed",
		"type": TYPE_OBJECT,
		"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE if ui_detail_type == enums.E_UIDetailType.DEBUG_BUTTON else PROPERTY_USAGE_STORAGE,
		"hint": PROPERTY_HINT_RESOURCE_TYPE,
		"hint_string": "Texture2D"
	})
	
	properties.append({
		"name": "texture_hovered",
		"type": TYPE_OBJECT,
		"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE if ui_detail_type == enums.E_UIDetailType.DEBUG_BUTTON else PROPERTY_USAGE_STORAGE,
		"hint": PROPERTY_HINT_RESOURCE_TYPE,
		"hint_string": "Texture2D"
	})
	
	return properties
