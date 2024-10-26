# Selection Handler
extends Node2D

signal selection_changed(selection)

var mouse_hovered_unit
var mouse_hovered_ui_element
var selected_units = []

var _current_selected_object
var _stop_drawing_dude = true
var _selection_box_start_pos
var _select_box = Rect2()
var _selection_grid : SelectionGrid

@export var _debug_selection = false

# debug vars
var mouse_hovered_unit_label = Label.new()

func _ready() -> void:
	get_tree().create_timer(.2).timeout.connect(timer_timeout)
	z_index = Globals.top_z_index # this keeps the select box on top of everything
	InputManager.left_click_pressed.connect(_select)
	InputManager.left_click_released.connect(_select)

func _process(delta: float) -> void:
	queue_redraw()

func _draw():
	if(_stop_drawing_dude):
		return
	_select_box.position = _selection_box_start_pos
	_select_box.end = get_global_mouse_position()
	draw_rect(_select_box, Color.WEB_GREEN, false)

func remove_from_selection(unit) -> void:
	var index = selected_units.find(unit)
	if index == -1:
		return
	
	selected_units.remove_at(index)

# Doesn't work because it fires the event twice. One call for graphics frame and one for physics frame
# more info here: https://stackoverflow.com/questions/69981662/godot-input-is-action-just-pressed-runs-twice
# DOES work I just had two Selection Handlers in the scene because autoload and I had one I put there
func _select(event):
	if BuildManager.get_ghost() != null or mouse_hovered_ui_element != null:
		return
	
	if event.is_pressed():
		_stop_drawing_dude = false
		_selection_box_start_pos = get_global_mouse_position()
	elif event.is_released():
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
	
	_select_units()
	_select_selectable_objects()

func _select_units():
	var newly_selected_units = []
	if _select_box.size != Vector2.ZERO:
		newly_selected_units = _selection_grid.get_units_in_select_box(_select_box)
		
	if mouse_hovered_unit != null:
		if _select_box.size == Vector2.ZERO:
			newly_selected_units = [mouse_hovered_unit]
		else:
			newly_selected_units.push_back(mouse_hovered_unit)
		
	selection_changed.emit(newly_selected_units)
	
	# gotta turn off selection circle for old selected units
	# TODO: could probably optimize this to leave units 
	#		in both old and new selection alone
	if selected_units != null:
		for u in selected_units:
			u.set_selection_circle_visible(false)
			u._in_selection = false

	# finished with old units, store new selected units
	selected_units = newly_selected_units
	
	for u in selected_units:
		u.set_selection_circle_visible(true)
		u._in_selection = true

func _select_selectable_objects():
	if _current_selected_object != CursorManager.current_hovered_inanimate_object:
		if _current_selected_object != null:
			_current_selected_object.set_selection_circle_visible(false)
		_current_selected_object = CursorManager.current_hovered_inanimate_object
	
	if _current_selected_object == null:
		return
	
	_current_selected_object.set_selection_circle_visible(true)
	Hud.update_selection([_current_selected_object])

func has_units_selected() -> bool:
	return selected_units.size() > 0

#TODO: make this wait on a signal instead
# weird hack to wait for setting selection grid
func timer_timeout():
	_selection_grid = get_node("/root/main/SelectionGrid")
	if(_selection_grid == null):
		get_tree().create_timer(.2).timeout.connect(timer_timeout)
