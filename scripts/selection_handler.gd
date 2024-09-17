extends Node2D

signal _variable_set(v)

var mouse_hovered_unit
var unit_array = Array()
var selected_units = []

var _stop_drawing_dude = true
var _selection_box_start_pos
var _select_box = Rect2()
var _selection_grid

@export var _debug_selection = false

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
		_handle_click_release()


func _handle_click_release():
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
	
	var newly_selected_units = []
	if _select_box.size.length() == 0:
		print("select box is size zero, no units selected")
		print("we must select a single unit, check if we're hovered over a unit")
		if mouse_hovered_unit != null:
			newly_selected_units = [mouse_hovered_unit]
		
	else:
		newly_selected_units = _selection_grid.get_units_in_select_box(_select_box)
	
	print("newly_selected_units length = %s" % newly_selected_units.size())
	
	# gotta turn off selection circle for old selected units
	# TODO: could probably optimize this to leave units 
	#		in both old and new selection alone
	for u in selected_units:
		u.set_selection_circle_visible(false)

	# finished with old units, store new selected units
	selected_units = newly_selected_units
	
	for u in selected_units:	
		u.set_selection_circle_visible(true)


func timer_timeout():
	_selection_grid = get_node("/root/main/SelectionGrid")
	if(_selection_grid == null):
		get_tree().create_timer(.2).timeout.connect(timer_timeout)
