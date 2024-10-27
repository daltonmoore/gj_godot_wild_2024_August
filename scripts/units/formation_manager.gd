extends Node2D

#@export var __debug_test_grid_locked_units : Array[GridLockedUnit]
@export var grid_size := 48
@export var max_formation_width = 6

@onready var tile_map_layer: MyTileMap = $"../TileMapLayer"

func _ready() -> void:
	z_index = Globals.top_z_index
	InputManager.right_click_pressed.connect(get_formation_for_currently_selected_units)
	
	if !Globals.debug:
		return
	
	for x in 20:
		for y in 20:
			DebugDraw2d.rect(tile_map_layer.map_to_local(Vector2i(x,y)), Vector2(grid_size, grid_size), Color.BLUE,1, INF)

func get_formation_for_currently_selected_units(_event) -> void:
	# do not do a move formation if we are issuing an attack order on a single unit.
	# could be a problem when we do attack move
	if (CursorManager.cursor_over_anything() or 
			(SelectionHandler.selected_units.size() > 0 and 
			SelectionHandler.selected_units[0] != null and
			SelectionHandler.selected_units[0].team == enums.e_team.enemy)
	):
		return
		
	var mouse_pos = get_global_mouse_position()
	var marked_positions : Array
	var silent := false
	var col := 0
	var offset = Vector2.ZERO
	for unit in SelectionHandler.selected_units: # __debug_test_grid_locked_units
		if unit == null:
			continue
		
		var unit_destination_tile = null
		while unit_destination_tile == null:
			if col >= max_formation_width:
				offset = Vector2(0, offset.y + -1)
				col = 0
			var tile_pos = tile_map_layer.local_to_map(mouse_pos + offset)
			if !marked_positions.has(tile_pos):
				marked_positions.append(tile_pos)
				unit_destination_tile = tile_pos
				DebugDraw2d.rect(tile_map_layer.map_to_local(tile_pos), Vector2(grid_size, grid_size), Color.GREEN,1, 10)
				
				# for testing grid_locked_unit.gd
				#unit.set_move_to(tile_map_layer.map_to_local(tile_pos))
				#if !unit.is_moving:
					#unit.move()
				unit.order_move(tile_map_layer.map_to_local(tile_pos), enums.e_order_type.move, silent)
				silent = true # only first unit in selection may ack
			else:
				offset += Vector2.RIGHT * grid_size
				col += 1
