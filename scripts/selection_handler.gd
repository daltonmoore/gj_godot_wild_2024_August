class_name SelectionHandler
extends Node2D

signal _variable_set(v)

var unit_array = Array()
var _stop_drawing_dude = true
var _selection_box_start_pos
var _select_box = Rect2()
var _selection_grid
var _selected_units = []

@export var _debug_selection = false

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


func _ready() -> void:
	for i in get_tree().get_nodes_in_group(Globals.unit_group):
		print(i.get_path())
		unit_array.push_back(i)
	 
	get_tree().create_timer(.2).timeout.connect(timer_timeout)


func _process(delta: float) -> void:
	queue_redraw()


func _draw():	
	if(_stop_drawing_dude):
		return
	
	_select_box.position = _selection_box_start_pos
	_select_box.end = get_global_mouse_position()
	draw_rect(_select_box, Color.GREEN, false)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Left Click"):
		_stop_drawing_dude = false
		_selection_box_start_pos = get_global_mouse_position()
	elif event.is_action_released("Left Click"):
		_stop_drawing_dude = true
		
		var start = _select_box.position
		# (if size is negative then this will be the bottom left position) 
		var top_right = Vector2(_select_box.end.x, start.y)
		# (if size is negative then this will be the top right position) 
		var bot_left = Vector2(start.x, _select_box.end.y)
		var end = _select_box.end
		
		#region Debug Selection
		if _debug_selection:
			# Axes
			DebugDraw2d.line_vector(Vector2.ZERO,Vector2.UP*40, Color.BLACK, 1, INF)
			DebugDraw2d.line_vector(Vector2.ZERO,Vector2.DOWN*40, Color.BLACK, 1, INF)
			DebugDraw2d.line_vector(Vector2.ZERO,Vector2.RIGHT*40, Color.BLACK, 1, INF)
			DebugDraw2d.line_vector(Vector2.ZERO,Vector2.LEFT*40, Color.BLACK, 1, INF)
		
			var debug_box_lifetime = 3
			# _________________________________________________________________
			# Draw circles at the corners of the select box
			#
			# 1. Draw a circle at the start position of the select box
			DebugDraw2d.circle(start, 1, 32, Color.GREEN, 1, debug_box_lifetime)
			
			# 2. Draw a circle at the top right position of the select box
			DebugDraw2d.circle(top_right, 1, 32, Color.YELLOW, 1, debug_box_lifetime)
			
			# 3. Draw a circle at the bottom left position of the select box
			DebugDraw2d.circle(bot_left, 1, 32, Color.BLUE, 1, debug_box_lifetime)
			
			# 4. Draw a circle at the end position of the select box
			DebugDraw2d.circle(end, 1, 32, Color.DARK_ORANGE, 1, debug_box_lifetime)
			# _________________________________________________________________
			
			DebugDraw2d.line(start,top_right, Color.GREEN, .5, debug_box_lifetime)
			DebugDraw2d.line(start,bot_left, Color.GREEN, .5, debug_box_lifetime)
			DebugDraw2d.line(bot_left,end, Color.GREEN, .5, debug_box_lifetime)
			DebugDraw2d.line(top_right,end, Color.GREEN, .5, debug_box_lifetime)
		#endregion
		
		# Storing everything in Plane2Ds
		var top_plane = Plane2D.new(start, top_right)
		var right_plane = Plane2D.new(top_right, end)
		var bot_plane = Plane2D.new(end, bot_left)
		var left_plane = Plane2D.new(bot_left, start)
		
		if _select_box.size.length() == 0:
			print("returning early because select box is size zero")
			return
		
		_selected_units = _selection_grid.get_units_in_select_box(_select_box)
	elif event.is_action_pressed("Right Click"):
		if _selected_units == null:
			return
		for u in _selected_units:
			u.order_move()


func timer_timeout():
	_selection_grid = get_node("/root/main/SelectionGrid")
	if(_selection_grid == null):
		get_tree().create_timer(.2).timeout.connect(timer_timeout)

