extends Sprite2D

@export var move_speed := 0.5
@export var line : Line2D

@onready var tile_map_layer: TileMapLayer = $"../TileMapLayer"
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var ray_cast_2d: RayCast2D = $RayCast2D
@onready var collision_shape_2d: CollisionShape2D = $Area2D/CollisionShape2D

var astar_grid: AStarGrid2D
var current_path : Array[Vector2i]
var last_mouse_pos : Vector2
var is_moving = false

func _ready() -> void:
	InputManager.left_click_released.connect(_on_left_click_release)
	
	astar_grid = AStarGrid2D.new()
	astar_grid.region = tile_map_layer.get_used_rect()
	astar_grid.cell_size = Vector2(48, 48)
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()
	
	var region_size = astar_grid.region.size
	var region_position = astar_grid.region.position
	
	for x in region_size.x:
		for y in region_size.y:
			var tile_position =Vector2i(
				x + region_position.x,
				y + region_position.y
			)
			var tile_data = tile_map_layer.get_cell_tile_data(tile_position)
			
			if tile_data == null or not tile_data.get_custom_data("walkable"):
				astar_grid.set_point_solid(tile_position)

func _physics_process(delta: float) -> void:
	if is_moving:
		sprite_2d.global_position = sprite_2d.global_position.move_toward(global_position, move_speed)
		
		if sprite_2d.global_position != global_position:
			return
		
		if current_path.size() > 0:
			move()
		else:
			is_moving = false

func _on_left_click_release(_event) -> void:
	if is_moving:
		return
	
	last_mouse_pos = get_global_mouse_position()
	move()
	#move_old(global_position.direction_to(get_global_mouse_position()).round())

func move_old(direction: Vector2):
	var current_tile: Vector2i = tile_map_layer.local_to_map(global_position)
	var target_tile: Vector2i = Vector2i(
		current_tile.x + direction.x,
		current_tile.y + direction.y
	)
	prints(current_tile, target_tile)
	#walkable tile data
	var tile_data: TileData = tile_map_layer.get_cell_tile_data(target_tile)
	if tile_data.get_custom_data("walkable") == false:
		return
	
	ray_cast_2d.target_position = direction * 48
	ray_cast_2d.force_raycast_update()
	if ray_cast_2d.is_colliding():
		var target = ray_cast_2d.get_collider() # A CollisionObject2D.
		var shape_id = ray_cast_2d.get_collider_shape() # The shape index in the collider.
		var owner_id = target.shape_find_owner(shape_id) # The owner ID in the collider.
		var shape = target.shape_owner_get_owner(owner_id)
		print(shape.get_parent().get_parent().name)
	
	if ray_cast_2d.is_colliding() and ray_cast_2d.get_collider() != collision_shape_2d:
		return
	
	is_moving  = true
	
	global_position = tile_map_layer.map_to_local(target_tile)
	
	sprite_2d.global_position = tile_map_layer.map_to_local(current_tile)

func move():
	var friendly_units = get_tree().get_nodes_in_group("friendly_units")
	var occupied_positions = []
	
	for unit in friendly_units:
		if unit == self:
			continue
		
		occupied_positions.append(tile_map_layer.local_to_map(unit.global_position))
	
	for pos in occupied_positions:
		astar_grid.set_point_solid(pos)
	
	current_path = astar_grid.get_id_path(
		tile_map_layer.local_to_map(global_position),
		tile_map_layer.local_to_map(last_mouse_pos)
	)
	
	for pos in occupied_positions:
		astar_grid.set_point_solid(pos, false)
	
	# remove current position from path
	current_path.pop_front()
	
	if current_path.is_empty():
		print("can't find path")
		return
	
	var orignal_position = Vector2(global_position)
	global_position = tile_map_layer.map_to_local(current_path[0])
	sprite_2d.global_position = orignal_position
	
	is_moving = true
	
	var debug_array_of_points_in_global : Array
	for point in current_path:
		debug_array_of_points_in_global.append(tile_map_layer.map_to_local(point))
	line.points = PackedVector2Array(debug_array_of_points_in_global)
