extends Node

var selection_grid_cell = preload("res://scenes/selection_grid_cell.tscn")
# Key: Vector2
# Value: SelectionGridCell
var cell_dict = {}

# Key: Vector2
# Value: Unit Array
var cell_to_units_dict = {}

var grid_width = 5
var grid_height = 5

var debug = Globals.debug

@export var size = Vector2(100,100)

func _ready() -> void:	
	var x = 0 
	var y = 0
	var grid_start_offset = Vector2(50,50)
	for i in grid_height:
		for k in grid_width:
			var pos = Vector2(x, y) + grid_start_offset
			if debug:
				DebugDraw2d.rect(pos, size, Color(1, 0, 1), 1, INF)
			
			var cell = selection_grid_cell.instantiate()
			cell.position = pos
			(cell.get_child(0) as CollisionShape2D).shape.size = size
			cell.grid_pos = Vector2(x/size.x, y/size.x) 
			cell.grid_index = cell.grid_pos.x + (cell.grid_pos.y * grid_width)
			add_child(cell)
			
			if debug:
				# Debug coordinate text
				var label = Label.new()
				label.text = "%.v" % cell.grid_pos
				cell.add_child(label)
				label.position = Vector2(-size.x/2,-size.x/2) # is relative pos
			
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
# TODO: this function is too big, also why did i move this to selection_grid?
func get_units_in_select_box(select_box):
	var corners = _get_select_box_corners(select_box)
	assert (len(corners) == 4)
	var top_left = corners["tl"]
	var top_right = corners["tr"]
	var bot_right = corners["br"]
	var bot_left = corners["bl"]
	
	var top_left_coord: Vector2 = Vector2(floori(top_left.x / size.x), 
			floori(top_left.y / size.x))
	var bot_right_coord: Vector2 = Vector2(floori(bot_right.x / size.x), 
			floori(bot_right.y / size.x))
	var top_right_coord: Vector2 = Vector2(floori(top_right.x / size.x), 
			floori(top_right.y / size.x))
	var bot_left_coord: Vector2 = Vector2(floori(bot_left.x / size.x), 
			floori(bot_left.y / size.x))
	
	# TODO:make a function that will take a vector2 and flatten it into an array index
	var start_index = top_left_coord.x + top_left_coord.y * grid_width
	var end_index = bot_right_coord.x + bot_right_coord.y * grid_width
	
	# Get selected cells
	var cells = cell_dict.values()
	var selected_cells = []
	for i in cells.size():
		if(i + start_index >= cells.size()):
			break
		
		if (i + start_index > end_index):
			break
		
		var item = cells[start_index + i]
		if item.grid_pos.x > bot_right_coord.x:
			continue
			
		if item.grid_pos.x < top_left_coord.x:
			continue
		
		if debug:
			DebugDraw2d.rect(item.position, size, Color(0, 1, 0), 1, 2)
		selected_cells.append(item)
	
	# Storing everything in Plane2Ds	
	var top_plane = Plane2D.new(top_left, top_right)
	var right_plane = Plane2D.new(top_right, bot_right)
	var bot_plane = Plane2D.new(bot_right, bot_left)
	var left_plane = Plane2D.new(bot_left, top_left)

	var planes = [top_plane, right_plane, bot_plane, left_plane]
	
	# get units within selected cells
	var unit_array = []
	for i in selected_cells:
		if (cell_to_units_dict.has(i.grid_pos)):
			unit_array.append_array(cell_to_units_dict[i.grid_pos])
	
	# debug plane placement
	if debug:
		var debug_i = 0
		for p in planes:
			match debug_i:
				0:
					DebugDraw2d.line(p.point_a, p.point_b, Color.BLUE, 1, 3)
				1:
					DebugDraw2d.line(p.point_a, p.point_b, Color.RED, 1, 3)
				2:
					DebugDraw2d.line(p.point_a, p.point_b, Color.GREEN, 1, 3)
				3:
					DebugDraw2d.line(p.point_a, p.point_b, Color.YELLOW, 1, 3)
			debug_i += 1
	
	# check if units are in select box
	var selected_units = []
	for u in unit_array:
		var inside = true
		var p_index = 0
		for p in planes:
			var distance = p.normal.dot(u.position) - p.d
			if (distance > 0):
				inside = false
				break
			p_index += 1
		if inside:
			#DebugDraw2d.circle(u.position, 10, 32, Color.GREEN, 1, 1)
			selected_units.append(u)
		#else:
			#DebugDraw2d.circle(u.position, 10, 32, Color.RED, 1, 1)
	return selected_units
	

func _get_select_box_corners(select_box):
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
	
	func _to_string():
		var format_string = "Point A = %v \nPoint B = %v \nNormal = %v \nD = %d"
		return format_string % [point_a, point_b, normal, d]
