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

@export var size = Vector2(100,100)

func _ready() -> void:	
	var x = 0 
	var y = 0
	var grid_start_offset = Vector2(50,50)
	for i in grid_height:
		for k in grid_width:
			var pos = Vector2(x, y) + grid_start_offset
			DebugDraw2d.rect(pos, size, Color(1, 0, 1), 1, INF)
			
			var cell = selection_grid_cell.instantiate()
			cell.position = pos
			(cell.get_child(0) as CollisionShape2D).shape.size = size
			cell.grid_pos = Vector2(x/size.x, y/size.x) 
			cell.grid_index = cell.grid_pos.x + (cell.grid_pos.y * grid_width)
			add_child(cell)
			
			# Debug coordinate text
			var label = Label.new()
			label.text = "%.v" % cell.grid_pos
			cell.add_child(label)
			label.position = Vector2(-size.x/2,-size.x/2) # is relative pos
			
			cell_dict[cell.grid_pos] = cell
			#print(cell.grid_pos)
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
	#for u in cell_to_units_dict[cell]:
		#print(u)
	print("Body %s entered cell %s" % [body.name, cell.grid_pos])
	pass


func cell_exited(cell, body):
	# could be slow since we shift everything after the item
	if cell_to_units_dict[cell.grid_pos].has(body):
		cell_to_units_dict[cell.grid_pos].erase(body)
		print("Body %s exited cell %s" % [body.name, cell.grid_pos])
	else:
		print("Body %s is not in cell %s" % [body.name, cell.grid_pos])


# Thought Process to not have to iterate through entire grid 
# to find which cell we are trying to select units in
#______________________________________________________________________
# so we divide by 100 because the size of each cell is 100
# this will give us a cell index to start with for the selection box
# so if start is (500,300) and end is (200,200) 
# we'll have start cell = (5,3) and end cell = (2, 2)
# so instead of starting at cell (0, 0), we will just start at (2, 2) 
# because it is the lesser of the two points. And we can iterate
# TODO: this function is too big
func get_units_in_select_box(select_box):
	var top_right = Vector2(select_box.end.x, select_box.position.y)
	var bot_left = Vector2(select_box.position.x, select_box.end.y)
	
	var start_coord: Vector2 = Vector2(floori(select_box.position.x / size.x), 
			floori(select_box.position.y / size.x))
	var end_coord: Vector2 = Vector2(floori(select_box.end.x / size.x), 
			floori(select_box.end.y / size.x))
	var top_right_coord: Vector2 = Vector2(floori(top_right.x / size.x), 
			floori(top_right.y / size.x))
	var bot_left_coord: Vector2 = Vector2(floori(bot_left.x / size.x), 
			floori(bot_left.y / size.x))
	
	if start_coord.y < end_coord.y:
		print("s's y is less than e's")
	elif start_coord.x < end_coord.x:
		print("s's x is less than e's")
	else:
		print("e's y/x is less than s's")
		var temp = start_coord
		start_coord = end_coord
		end_coord = temp
	
	if(select_box.size.x < 0 and select_box.size.y < 0):
		var temp = bot_left
		bot_left = top_right
		top_right = temp
	elif select_box.size.x < 0: # only x is negative
		# top right is start point
		# bot left is end point
		var temp = top_right_coord
		top_right_coord = start_coord # i'm always assuming start point is top left usually
		start_coord = temp
		
		temp = bot_left_coord
		bot_left_coord = end_coord
		end_coord = temp
	elif select_box.size.y < 0:
		# bot left is start point
		# top right is end point
		var temp = bot_left_coord
		bot_left_coord = start_coord 
		start_coord = temp
		
		temp = top_right_coord
		top_right_coord = end_coord
		end_coord = temp
	
	#print("Box Size %.v" % select_box.size)
	#print("top_right %.v" % top_right_coord)
	#print("bot_left %.v" % bot_left_coord)
	
	#DebugDraw2d.circle(top_right, 10, 16, Color(0, 1, 0), 1, 2)
	#DebugDraw2d.circle(bot_left, 10, 16, Color(0, 0, 1), 1, 2)
	
	# TODO:make a function that will take a vector2 and flatten it into an array index
	var start_index = start_coord.x + start_coord.y * grid_width
	var end_index = end_coord.x + end_coord.y * grid_width
	
	var cells = cell_dict.values()
	var selected_cells = []
	for i in cells.size():
		if(i + start_index >= cells.size()):
			break
		
		if (i + start_index > end_index):
			break
		
		var item = cells[start_index + i]
		if item.grid_pos.x > end_coord.x:
			continue
			
		if item.grid_pos.x < start_coord.x:
			continue
		
		DebugDraw2d.rect(item.position, size, Color(0, 1, 0), 1, 2)
		selected_cells.append(item)
	
	#var start = _select_box.position
	#var top_right = Vector2(_select_box.end.x, start.y)
	#var bot_left = Vector2(start.x, _select_box.end.y)
	#var end = _select_box.end
	
	# Storing everything in Plane2Ds
	var top_plane = Plane2D.new(select_box.position, top_right)
	var right_plane = Plane2D.new(top_right, select_box.end)
	var bot_plane = Plane2D.new(select_box.end, bot_left)
	var left_plane = Plane2D.new(bot_left, select_box.position)
	
	var unit_array = []
	for i in selected_cells:
		if (cell_to_units_dict.has(i.grid_pos)):
			#print("Cell to units has grid_pos %.v" % i.grid_pos)
			unit_array.append_array(cell_to_units_dict[i.grid_pos])
			#print(cell_to_units_dict[i.grid_pos])
		else:
			#print("Cell to units does not have grid_pos %.v" % i.grid_pos)
			pass
	
	var planes = [top_plane, right_plane, bot_plane, left_plane]
	
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
			DebugDraw2d.circle(u.position, 10, 32, Color.GREEN, 1, INF)
			selected_units.append(u)
		else:
			DebugDraw2d.circle(u.position, 10, 32, Color.RED, 1, INF)
	return selected_units
	

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
