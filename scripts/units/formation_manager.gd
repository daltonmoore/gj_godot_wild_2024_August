extends Node2D
@onready var tile_map_layer: MyTileMap = $"../TileMapLayer"

@export var __debug_test_grid_locked_units : Array

func _ready() -> void:
	return
	z_index = Globals.top_z_index
	InputManager.left_click_released.connect(get_formation_for_currently_selected_units)
	for x in 20:
		for y in 20:
			DebugDraw2d.rect(tile_map_layer.map_to_local(Vector2i(x,y)), Vector2(48,48), Color.BLUE,1, INF)

func get_formation_for_currently_selected_units(_event) -> void:
	var mouse_pos = get_global_mouse_position()
	var marked_positions : Array
	for unit_node_path in __debug_test_grid_locked_units:
		var unit_destination_tile = null
		var unit = get_node(unit_node_path) as GridLockedUnit
		
		# I have mouse pos 
		# I need to get the tiles around that mouse pos
		var offset = Vector2.ZERO
		while unit_destination_tile == null:
			var tile_pos = tile_map_layer.local_to_map(mouse_pos + offset)
			if !marked_positions.has(tile_pos):
				marked_positions.append(tile_pos)
				unit_destination_tile = tile_pos
				DebugDraw2d.rect(tile_map_layer.map_to_local(tile_pos), Vector2(48,48), Color.GREEN,1, 10)
				print("marked pos %s" % tile_pos)
				unit.set_move_to(tile_map_layer.map_to_local(tile_pos))
				if !unit.is_moving:
					unit.move()
			else:
				offset += Vector2.RIGHT
