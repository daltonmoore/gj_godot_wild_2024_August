# Selection Handler
extends Node2D

signal selection_changed(selection)

var mouse_hovered_unit: Unit
var mouse_hovered_ui_element
var selected_things: Array[Variant] = []

var _current_selected_object
var _double_click_timer = Timer.new()
var _stop_drawing_dude = true
var _selection_box_start_pos
var _select_box         = Rect2()
var _selection_grid : SelectionGrid


# debug vars
var mouse_hovered_unit_label = Label.new()

func _ready() -> void:
	if Globals.debug:
		Hud.add_child(mouse_hovered_unit_label)
	_double_click_timer.wait_time = 0.25
	_double_click_timer.one_shot = true
	add_child(_double_click_timer)
	get_tree().create_timer(.2).timeout.connect(timer_timeout)
	z_index = Globals.top_z_index # this keeps the select box on top of everything
	InputManager.left_click_pressed.connect(_select)
	InputManager.left_click_released.connect(_select)

func _process(_delta: float) -> void:
	queue_redraw()
	if mouse_hovered_unit_label != null and mouse_hovered_unit != null:
		mouse_hovered_unit_label.text = mouse_hovered_unit.name

func _draw():
	if(_stop_drawing_dude):
		return
	_select_box.position = _selection_box_start_pos
	_select_box.end = get_global_mouse_position()
	draw_rect(_select_box, Color.WEB_GREEN, false)

func remove_from_selection(unit) -> void:
	var index = selected_things.find(unit)
	if index == -1:
		return
	
	selected_things.remove_at(index)

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
	
	if Globals.debug:
		# Axes
		DebugDraw2d.line_vector(Vector2.ZERO, Vector2.UP * 40, Color.BLACK, 1, INF)
		DebugDraw2d.line_vector(Vector2.ZERO, Vector2.DOWN * 40, Color.BLACK, 1, INF)
		DebugDraw2d.line_vector(Vector2.ZERO, Vector2.RIGHT * 40, Color.BLACK, 1, INF)
		DebugDraw2d.line_vector(Vector2.ZERO, Vector2.LEFT * 40, Color.BLACK, 1, INF)
	
		var debug_box_lifetime := 3
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
	
	if not _select_units():
		_select_selectable_objects()



func _select_units() -> bool:
	var newly_selected_units: Array[Variant] = _get_newly_selected_things(enums.e_object_type.unit)

	if not Input.is_action_pressed("Add To Selection"):
		_clear_old_selection()
	else:
		newly_selected_units.append_array(selected_things)

	_apply_new_selection(newly_selected_units)
	
	return newly_selected_units.size() > 0


func _get_newly_selected_things(object_type: enums.e_object_type) -> Array[Variant]:
	if _select_box.size != Vector2.ZERO:
		var units_in_box := _selection_grid.get_things_in_select_box(_select_box)
		for i in units_in_box.size():
			var thing: Movable = (units_in_box[i] as Movable) 
			if thing != null:
				DebugDraw2d.circle_filled(thing.position)
			
		return _handle_hover_unit_while_boxing_selection(units_in_box)

	return _handle_single_unit_selection()


func _handle_hover_unit_while_boxing_selection(things_in_box: Array[Variant]) -> Array[Variant]:
	var result := things_in_box
	if mouse_hovered_unit:
		result.push_back(mouse_hovered_unit)
	return result


func _handle_single_unit_selection() -> Array[Unit]:
	if not mouse_hovered_unit:
		return []
	
	if _is_double_clicking_selected_unit():
		return _selection_grid.get_things_in_select_box(get_viewport().get_visible_rect(), mouse_hovered_unit.unit_type)

	if _double_click_timer.is_stopped():
		_double_click_timer.start()

	return [mouse_hovered_unit]


func _is_double_clicking_selected_unit() -> bool:
	return selected_things != null \
	and !_double_click_timer.is_stopped() \
	and selected_things.size() > 0 \
	and selected_things[0] == mouse_hovered_unit


func _clear_old_selection() -> void:
	if not selected_things:
		return

	for thing in selected_things:
		thing.set_selection_circle_visible(false)
		thing.set_in_selection(false)


func _apply_new_selection(newly_selected_things: Array[Variant]) -> void:
	selected_things = newly_selected_things
	selection_changed.emit(newly_selected_things)

	for unit_node in selected_things:
		if not unit_node is Unit:
			continue

		var unit := unit_node as Unit
		unit.set_selection_circle_visible(true)
		unit.set_in_selection(true)

func _select_selectable_objects():
	if _current_selected_object != CursorManager.current_hovered_inanimate_object:
		if _current_selected_object != null:
			_current_selected_object.set_selection_circle_visible(false)
			_current_selected_object.in_selection = false
		_current_selected_object = CursorManager.current_hovered_inanimate_object
	
	if _current_selected_object == null:
		return
	
	_current_selected_object.set_selection_circle_visible(true)
	_current_selected_object.in_selection = true
	Hud.update_selection([_current_selected_object])

func has_units_selected() -> bool:
	return selected_things.size() > 0

#TODO: make this wait on a signal instead
# weird hack to wait for setting selection grid
func timer_timeout():
	_selection_grid = get_node("/root/main/SelectionGrid")
	if(_selection_grid == null):
		get_tree().create_timer(.2).timeout.connect(timer_timeout)
