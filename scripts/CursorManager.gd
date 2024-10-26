extends Node2D

signal mouse_over_object(object)

enum cursor_type {
	default,
	wood,
	select,
	building,
	attack
}

var current_hovered_tile : TileData
var current_hovered_inanimate_object : Selectable

var _cursor_select = load("res://art/cursors/mmorpg-cursorpack-Narehop/cursors/cursor1.png")
var _cursor_attack = load("res://art/cursors/mmorpg-cursorpack-Narehop/gold-pointer/pointer_23.png")
var _cursor_default = load("res://art/cursors/mmorpg-cursorpack-Narehop/cursors/cursor8.png")
var _current_cursor_type = cursor_type.default


func _ready() -> void:
	#Input.mouse_mode = Input.MOUSE_MODE_CONFINED
	InputManager.mouse_move.connect(_mouse_move)

func _mouse_move(event) -> void:
	if BuildManager._current_ghost != null:
		return
	
	# Updating cursor
	if SelectionHandler.mouse_hovered_unit != null:
		if cursor_over_enemy() and SelectionHandler.has_units_selected():
			Input.set_custom_mouse_cursor(_cursor_attack)
			_current_cursor_type = cursor_type.attack
		else:
			Input.set_custom_mouse_cursor(_cursor_select)
			_current_cursor_type = cursor_type.select
	else:
		Input.set_custom_mouse_cursor(_cursor_default)
		_current_cursor_type = cursor_type.default
	
	if (current_hovered_inanimate_object == null):
		return
	
	match current_hovered_inanimate_object.object_type:
		enums.e_object_type.resource:
			if (len(SelectionHandler.selected_units) > 0):
				Input.set_custom_mouse_cursor(current_hovered_inanimate_object.cursor_texture)
		_:
			Input.set_custom_mouse_cursor(current_hovered_inanimate_object.cursor_texture)
	

func cursor_over_anything() -> bool:
	return cursor_over_enemy() or cursor_over_resource() or cursor_over_selectable()

func cursor_over_selectable() -> bool:
	return current_hovered_inanimate_object != null

func cursor_over_enemy() -> bool:
	return SelectionHandler.mouse_hovered_unit != null and SelectionHandler.mouse_hovered_unit.team == enums.e_team.enemy

func cursor_over_resource() -> bool:
	return current_hovered_inanimate_object is RTS_Resource_Base

func set_current_hovered_object(object):
	current_hovered_inanimate_object = object
