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
var current_hovered_resource : RTS_Resource
var current_hovered_building : Building

var _cursor_select = load("res://art/cursors/mmorpg-cursorpack-Narehop/cursors/cursor1.png")
var _cursor_default = load("res://art/cursors/mmorpg-cursorpack-Narehop/cursors/cursor8.png")
var _cursor_wood = load("res://art/cursors/mmorpg-cursorpack-Narehop/gold-pointer/pointer_36.png")
var _cursor_building = load("res://art/cursors/mmorpg-cursorpack-Narehop/gold-pointer/pointer_17.png")

var _current_cursor_type = cursor_type.default

func _ready() -> void:
	#Input.mouse_mode = Input.MOUSE_MODE_CONFINED
	pass


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
		
		if (current_hovered_resource != null and
				len(_currently_selected_units) and
				current_hovered_resource.resource_type == enums.e_resource_type.wood):
			Input.set_custom_mouse_cursor(_cursor_wood)
			_current_cursor_type = cursor_type.wood
		elif (current_hovered_building != null):
			Input.set_custom_mouse_cursor(_cursor_building)
			_current_cursor_type = cursor_type.building


func cursor_over_selectable () -> bool:
	return current_hovered_object != null


func set_current_hovered_object(object, type):
	if object == null:
		match type:
			enums.e_object_type.resource:
				current_hovered_resource = null
			enums.e_object_type.building:
				current_hovered_building = null
		return
	
	current_hovered_object = object
	if object as RTS_Resource != null:
		current_hovered_resource = object as RTS_Resource
	elif object as Building != null:
		current_hovered_building = object as Building







