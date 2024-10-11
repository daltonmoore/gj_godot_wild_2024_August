class_name MyTileMap
extends TileMap

signal current_hovered_tile_changed(old_value, new_value)

var tile_data : TileData

var _cursor_select = load("res://art/cursors/mmorpg-cursorpack-Narehop/cursors/cursor1.png")
var _cursor_default = load("res://art/cursors/mmorpg-cursorpack-Narehop/cursors/cursor8.png")

func _ready() -> void:
	pass


func _physics_process(_delta):
	var mouse_pos = get_global_mouse_position()
	var tile_pos = local_to_map(mouse_pos)
	
	# layer 1 is the foreground
	# var new_tile_data = get_cell_tile_data(1, tile_pos)
	# layer 0 is the background
	var new_tile_data = get_cell_tile_data(0, tile_pos)
	if tile_data != new_tile_data:
		current_hovered_tile_changed.emit(tile_data, new_tile_data)
		tile_data = new_tile_data
