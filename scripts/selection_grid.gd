class_name SelectionGrid
extends Node

var selection_grid_cell: PackedScene = preload("res://scenes/selection_grid_cell.tscn")
# Key: Vector2
# Value: SelectionGridCell
var cell_dict: Dictionary = {}
# Key: Vector2
# Value: Unit Array
var cell_to_units_dict: Dictionary = {}
var debug: bool                    = Globals.debug

@export var size: Vector2 = Vector2(100, 100)
@export_range(1, 100) var grid_width := 5
@export_range(1, 100) var grid_height := 5

func _ready() -> void:
	var x: int                     = 0
	var y: int                     = 0
	var grid_start_offset: Vector2 = Vector2(50, 50)
	for i in grid_height:
		for k in grid_width:
			var pos: Vector2                           = Vector2(x, y) + grid_start_offset
			var cell: Node                             = selection_grid_cell.instantiate()
			var cell_collision_shape: CollisionShape2D = (cell.get_child(0) as CollisionShape2D)
			cell.position = pos
			cell_collision_shape.shape.size = size
			cell.grid_pos = Vector2(x/size.x, y/size.x) 
			cell.grid_index = cell.grid_pos.x + (cell.grid_pos.y * grid_width)
			add_child(cell)
			
			if debug:
				cell_collision_shape.debug_color = Color(1,0,1,.1)
				DebugDraw2d.rect(pos, size, Color(1, 0, 1), 1, INF)
				# Debug coordinate text
				var label = Label.new()
				label.text = "%.v" % cell.grid_pos
				cell.add_child(label)
				label.position = Vector2(-size.x/2,-size.x/2) # is relative pos
			else:
				cell_collision_shape.debug_color = Color(0,0,0,0)
			
			cell_dict[cell.grid_pos] = cell
			x+=size.x
		x = 0
		y+=size.x

func get_cell_dict() -> Dictionary:
	return cell_dict

func cell_entered(cell, body):
	if cell_to_units_dict.has(cell.grid_pos):
		cell_to_units_dict[cell.grid_pos].append(body)
	else:
		cell_to_units_dict[cell.grid_pos] = [body]

func cell_exited(cell, body):
	# could be slow since we shift everything after the item
	if cell_to_units_dict[cell.grid_pos].has(body):
		cell_to_units_dict[cell.grid_pos].erase(body)

# Thought Process to not have to iterate through entire grid 
# to find which cell we are trying to select units in
#______________________________________________________________________
# so we divide by 100 because the size of each cell is 100
# this will give us a cell index to start with for the selection box
# so if start is (500,300) and end is (200,200) 
# we'll have start cell = (5,3) and end cell = (2, 2)
# so instead of starting at cell (0, 0), we will just start at (2, 2) 
# because it is the lesser of the two points. And we can iterate
func get_things_in_select_box(select_box: Rect2, unit_type := enums.E_UnitType.NONE, 
		object_type := enums.e_object_type.none) -> Array[Variant]:
	var corners: 		Dictionary 	= _get_select_box_corners(select_box)
	var grid_coords: 	Dictionary 	= _calculate_grid_coordinates(corners)
	var selected_cells: Array 		= _get_cells_in_range(grid_coords)
	var planes: 		Array 		= _create_boundary_planes(corners)
	var things:			Array		= _get_things_from_cells(selected_cells)

	return _filter_things_in_box(things, planes, unit_type)


func _calculate_grid_coordinates(corners: Dictionary) -> Dictionary:
	var top_left_coord  := Vector2(floori(corners["tl"].x / size.x),
	floori(corners["tl"].y / size.x))
	var bot_right_coord := Vector2(floori(corners["br"].x / size.x),
	floori(corners["br"].y / size.x))

	return {
		"top_left": top_left_coord,
		"bot_right": bot_right_coord,
		"start_index": top_left_coord.x + top_left_coord.y * grid_width,
		"end_index": bot_right_coord.x + bot_right_coord.y * grid_width
	}


func _get_cells_in_range(grid_coords: Dictionary) -> Array[Variant]:
	var cells: Array = cell_dict.values()
	var selected_cells: Array[Variant] = []

	for i in cells.size():
		if i + grid_coords["start_index"] >= cells.size() or \
		i + grid_coords["start_index"] > grid_coords["end_index"]:
			break

		var item = cells[grid_coords["start_index"] + i]
		if item.grid_pos.x > grid_coords["bot_right"].x or \
		item.grid_pos.x < grid_coords["top_left"].x:
			continue

		if debug:
			DebugDraw2d.rect(item.position, size, Color(0, 1, 0), 1, 2)
		selected_cells.append(item)

	return selected_cells


func _create_boundary_planes(corners: Dictionary) -> Array[Variant]:
	var planes := [
				  Plane2D.new(corners["tl"], corners["tr"]), # top
				  Plane2D.new(corners["tr"], corners["br"]), # right
				  Plane2D.new(corners["br"], corners["bl"]), # bottom
				  Plane2D.new(corners["bl"], corners["tl"])   # left
				  ]

	if debug:
		_debug_draw_planes(planes)

	return planes


func _get_things_from_cells(cells: Array) -> Array[Variant]:
	var thing_array: Array[Variant] = []
	for cell in cells:
		if cell_to_units_dict.has(cell.grid_pos):
			thing_array.append_array(cell_to_units_dict[cell.grid_pos])
	return thing_array


func _filter_things_in_box(things: Array[Variant], planes: Array, unit_type: enums.E_UnitType) -> Array[Variant]:
	var selected_things: Array[Variant] = []

	for thing in things:
		var should_select := false
		
		if thing as Unit:
			if _matches_unit_type(thing, unit_type): 
				should_select = _is_thing_inside_planes(thing, planes)
		elif thing as Movable:
			should_select = _is_thing_inside_planes(thing, planes)
		
		if should_select: 
			selected_things.append(thing)
		
		if debug:
			if should_select:
				DebugDraw2d.circle(thing.position, 10, 32, Color.GREEN, 1, 1)
			else:
				DebugDraw2d.circle(thing.position, 10, 32, Color.RED, 1, 1)

	return selected_things



func _matches_unit_type(unit: Unit, unit_type: enums.E_UnitType) -> bool:
	if unit_type != enums.E_UnitType.NONE and unit.unit_type != unit_type:
		if debug:
			print("Unit %s's Unit Type is %d and the passed Unit Type selector is %d" % [unit.name, unit.unit_type, unit_type])
			DebugDraw2d.circle(unit.position, 10, 32, Color.RED, 1, 1)
		return false
	return true


func _is_thing_inside_planes(thing: Variant, planes: Array) -> bool:
	for plane in planes:
		var distance = plane.normal.dot(thing.position) - plane.d
		if distance > 0:
			return false
	return true


func _debug_draw_planes(planes: Array) -> void:
	var colors := [Color.BLUE, Color.RED, Color.GREEN, Color.YELLOW]
	for i in planes.size():
		var plane = planes[i]
		DebugDraw2d.line(plane.point_a, plane.point_b, colors[i], 1, 3)


func remove_unit_from_cell_dict(unit) -> void:
	if !cell_to_units_dict.has(unit._current_cell.grid_pos):
		push_warning("Unit not in Cell Dictionary")
		return

	cell_to_units_dict[unit._current_cell.grid_pos].erase(unit)


func _get_select_box_corners(select_box) -> Dictionary:
	var top_left
	var top_right
	var bot_right
	var bot_left
	
	# started in bot right and ended in top left
	if(select_box.size.x < 0 and select_box.size.y < 0): 
		top_left = select_box.end
		top_right = Vector2(select_box.position.x, select_box.end.y)
		bot_right = select_box.position
		bot_left = Vector2(select_box.end.x, select_box.position.y)
	elif select_box.size.x < 0: # started in top left and ended bot left
		top_left = Vector2(select_box.end.x, select_box.position.y)
		top_right = select_box.position
		bot_right = Vector2(select_box.position.x, select_box.end.y)
		bot_left = select_box.end
	elif select_box.size.y < 0: # started in bot left and ended top right
		top_left = Vector2(select_box.position.x, select_box.end.y)
		top_right = select_box.end
		bot_right = Vector2(select_box.end.x, select_box.position.y)
		bot_left = select_box.position
	else: # started in top left and ended in bot right
		top_left = select_box.position
		top_right = Vector2(select_box.end.x, select_box.position.y)
		bot_right = select_box.end
		bot_left = Vector2(select_box.position.x, select_box.end.y)
	
	return {"tl": top_left, "tr": top_right, "br": bot_right, "bl": bot_left}


#func get_cell_position(pos) -> Vector2:
	#var x = int(pos.x / 100)
	#var y = int(pos.y / 100)
	#var temp = Vector2(x,y)
	#return cell_dict[temp]

class Plane2D:
	#var right_edge = top_right.direction_to(end)
	#var right_normal = Vector2(right_edge.y, -right_edge.x)
	#var right_edge_mid_point = top_right / 2 + end / 2
	#var right_D = right_normal.dot(right_edge_mid_point) # does the point matter? don't think so
	#var right_plane = Plane2D.new(top_right, end, right_normal, right_D)
	
	var point_a = Vector2()
	var point_b = Vector2()
	var normal = Vector2()
	var d = 0.0
	
	func _init(a, b):
		# idk if i need to do the mid point
		var mid_point = a / 2 + b / 2
		var edge = a.direction_to(b)
		
		point_a = a
		point_b = b
		normal = Vector2(edge.y, -edge.x)
		d = normal.dot(mid_point)
		
		assert(normal == self.normal)



	func _to_string() -> String:
		var format_string: String = "Point A = %v \nPoint B = %v \nNormal = %v \nD = %d"
		return format_string % [point_a, point_b, normal, d]
