extends Node2D

signal mouse_over_object(object)

var current_hovered_tile : TileData

var _cursor_select = load("res://art/cursors/mmorpg-cursorpack-Narehop/cursors/cursor1.png")
var _cursor_default = load("res://art/cursors/mmorpg-cursorpack-Narehop/cursors/cursor8.png")

func _ready() -> void:
	GlobalTileMap.current_hovered_tile_changed.connect(_hovered_tile_changed)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var local_mouse_pos = get_local_mouse_position()
		
		if SelectionHandler.mouse_hovered_unit != null:
			Input.set_custom_mouse_cursor(_cursor_select)
		elif current_hovered_tile != null and current_hovered_tile.get_custom_data("Selectable"):
			Input.set_custom_mouse_cursor(_cursor_select)
		else:
			Input.set_custom_mouse_cursor(_cursor_default)


func _hovered_tile_changed(old_tile, new_tile):
	current_hovered_tile = new_tile
	print(old_tile)



