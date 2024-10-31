extends Node2D
@export var line : Line2D

var navigation_mesh: NavigationPolygon
var source_geometry : NavigationMeshSourceGeometryData2D
var callback_parsing : Callable
var callback_baking : Callable
var region_rid: RID
var _bake_queue: Array[BakeQueueItem]
var _node_to_obstruction_dict: Dictionary = {}
var __debug_nav_polygons = [] # for debug drawing

func _ready() -> void:
	navigation_mesh = NavigationPolygon.new()
	navigation_mesh.agent_radius = 10.0
	source_geometry = NavigationMeshSourceGeometryData2D.new()
	callback_parsing = on_parsing_done
	callback_baking = on_baking_done
	region_rid = NavigationServer2D.region_create()

	# Enable the region and set it to the default navigation map.
	NavigationServer2D.region_set_enabled(region_rid, true)
	NavigationServer2D.region_set_map(region_rid, get_world_2d().get_navigation_map())
	
	parse_source_geometry.call_deferred()

func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	#for polygon in nav_polygons:
		#draw_polygon(polygon, PackedColorArray([Color(0, 1, .5, .3)]))
	
	for obstacle in _node_to_obstruction_dict.values():
		if obstacle.size() >= 3:
			draw_polygon(obstacle, PackedColorArray([Color.RED]))
	
	#draw_circle(point, 4, Color.BLACK)

func update_obstacle(node, polygon: Polygon2D, callable) -> void:
	var item = BakeQueueItem.new()
	item.node = node
	item.polygon = polygon
	item.callable = callable
	
	if NavigationServer2D.is_baking_navigation_polygon(navigation_mesh):
		_bake_queue.append(item)
		return
	
	_bake_obstacle(item)

func _bake_obstacle(bake_queue_item):
	# doesn't use agent radius for affecting nav mesh
	#var obstacle_carve: bool = true
	#source_geometry.add_projected_obstruction(obstacle_outline, obstacle_carve)
	
	# shift the polygon's points by its global position
	var temp_polygon_outline = bake_queue_item.polygon.polygon
	for i in range(temp_polygon_outline.size()):
		temp_polygon_outline[i] += bake_queue_item.polygon.global_position
	
	if !_node_to_obstruction_dict.has(bake_queue_item.node):
		source_geometry.add_obstruction_outline(temp_polygon_outline)
	
	# update the polygon that we have for that node in the dict
	_node_to_obstruction_dict[bake_queue_item.node] = temp_polygon_outline
	source_geometry.set_obstruction_outlines(_node_to_obstruction_dict.values())
	
	# Bake the navigation mesh on a thread with the source geometry data.
	NavigationServer2D.bake_from_source_geometry_data_async(
		navigation_mesh,
		source_geometry,
		callback_baking
	)

func _on_worker_path_changed(path: Variant) -> void:
	line.points = path

func parse_source_geometry() -> void:
	source_geometry.clear()
	var root_node: Node2D = self

	# Parse the obstruction outlines from all child nodes of the root node by default.
	NavigationServer2D.parse_source_geometry_data(
		navigation_mesh,
		source_geometry,
		root_node,
		callback_parsing
	)

func on_parsing_done() -> void:
	# If we did not parse a TileMap with navigation mesh cells we may now only
	# have obstruction outlines so add at least one traversable outline
	# so the obstructions outlines have something to "cut" into.
	source_geometry.add_traversable_outline(PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(1920.0, 0.0),
		Vector2(1920.0, 1080.0),
		Vector2(0.0, 1080.0)
	]))
	
	# for drawing later
	__debug_nav_polygons.append(PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(1920.0, 0.0),
		Vector2(1920.0, 1080.0),
		Vector2(0.0, 1080.0)
	]))
	
	var obstacle_outline = PackedVector2Array([
		Vector2(200, 200),
		Vector2(250, 200),
		Vector2(250, 250),
		Vector2(200, 250)
	])
	#obs_polygons.append(obstacle_outline)
	var obstacle_carve: bool = true
	source_geometry.add_projected_obstruction(obstacle_outline, obstacle_carve)
	
	# Bake the navigation mesh on a thread with the source geometry data.
	NavigationServer2D.bake_from_source_geometry_data_async(
		navigation_mesh,
		source_geometry,
		callback_baking
	)

func on_baking_done() -> void:
	# Update the region with the updated navigation mesh.
	NavigationServer2D.region_set_navigation_polygon(region_rid, navigation_mesh)
	
	if _bake_queue.size() > 0:
		_bake_obstacle(_bake_queue[0])
		_bake_queue.remove_at(0)


class BakeQueueItem:
	var node
	var polygon : Polygon2D
	var callable : Callable
