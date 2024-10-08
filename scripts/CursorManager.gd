extends Node2D

signal mouse_over_object(object)

enum cursor_type {
	default,
	wood,
	select,
	building
}

var current_hovered_tile : TileData
var current_hovered_object : Selectable

var _cursor_select = load("res://art/cursors/mmorpg-cursorpack-Narehop/cursors/cursor1.png")
var _cursor_default = load("res://art/cursors/mmorpg-cursorpack-Narehop/cursors/cursor8.png")
var _current_cursor_type = cursor_type.default


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var _currently_selected_units = SelectionHandler.selected_units
		
		# Updating cursor
		if SelectionHandler.mouse_hovered_unit != null:
			Input.set_custom_mouse_cursor(_cursor_select)
			_current_cursor_type = cursor_type.select
		else:
			Input.set_custom_mouse_cursor(_cursor_default)
			_current_cursor_type = cursor_type.default
		
		if (current_hovered_object != null):
			match current_hovered_object.object_type:
				enums.e_object_type.resource:
					if (len(SelectionHandler.selected_units) > 0):
						Input.set_custom_mouse_cursor(current_hovered_object.cursor_texture)
				_:
					Input.set_custom_mouse_cursor(current_hovered_object.cursor_texture)
			


func cursor_over_selectable() -> bool:
	return current_hovered_object != null
	
func cursor_over_resource() -> bool:
	return current_hovered_object is RTS_Resource_Base

func set_current_hovered_object(object):
	current_hovered_object = object








