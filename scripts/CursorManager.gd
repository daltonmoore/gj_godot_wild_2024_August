extends Node2D

signal mouse_over_object(object)

enum cursor_type {
	default,
	wood,
	select
}

var current_hovered_tile : TileData

var _cursor_select = load("res://art/cursors/mmorpg-cursorpack-Narehop/cursors/cursor1.png")
var _cursor_default = load("res://art/cursors/mmorpg-cursorpack-Narehop/cursors/cursor8.png")
var _cursor_wood = load("res://art/cursors/mmorpg-cursorpack-Narehop/gold-pointer/pointer_36.png")

var _current_cursor_type = cursor_type.default

func _ready() -> void:
	GlobalTileMap.current_hovered_tile_changed.connect(_hovered_tile_changed)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var _currently_selected_units = SelectionHandler.selected_units
		
		if SelectionHandler.mouse_hovered_unit != null:
			Input.set_custom_mouse_cursor(_cursor_select)
			_current_cursor_type = cursor_type.select
		else:
			Input.set_custom_mouse_cursor(_cursor_default)
			_current_cursor_type = cursor_type.default
		
		if current_hovered_tile != null:
			if (len(_currently_selected_units) and
					current_hovered_tile.get_custom_data("Type") == "Wood"):
				Input.set_custom_mouse_cursor(_cursor_wood)
				_current_cursor_type = cursor_type.wood
			elif current_hovered_tile.get_custom_data("Selectable"):
				Input.set_custom_mouse_cursor(_cursor_select)
				_current_cursor_type = cursor_type.select
		


func _hovered_tile_changed(old_tile, new_tile):
	current_hovered_tile = new_tile
	print(old_tile)
	
func cursor_over_resource () -> bool:
	return _current_cursor_type == cursor_type.wood



