extends Node2D

## This class is to manage issuing commands to selected units. Chop tree, attack 
## enemy, etc.

var _flashes = 5
var _current_flash_count = 0
var _flash_rate = .25
var _flash_on = false
var _flashing_hovered_object

func _ready() -> void:
	z_index = Globals.background_z_index
	$SelectedFlashTimer.timeout.connect(_on_resource_selected_flash_timer_timeout)
	$SelectedFlashTimer.wait_time = _flash_rate
	InputManager.right_click_pressed.connect(_order)


func _process(delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if _flash_on and _flashing_hovered_object != null:
		var pos = _flashing_hovered_object.position
		draw_rect(
			Rect2(pos - _flashing_hovered_object.visual_size / 2, _flashing_hovered_object.visual_size),
			Color.WEB_GREEN,
			false,
			2)

func _order(event) -> void:
	if SelectionHandler.selected_units != null:
		_order_units()


func _on_resource_selected_flash_timer_timeout():
	_flash_on = not _flash_on
	_current_flash_count += 1
	
	if _current_flash_count >= _flashes:
		_flash_on = false
		$SelectedFlashTimer.stop()


func _order_units() -> void:
	if BuildManager.get_ghost() != null:
		return
	
	if CursorManager.cursor_over_selectable():
		# collect resource
		_current_flash_count = 0
		$SelectedFlashTimer.stop()
		$SelectedFlashTimer.start()
		_flash_on = true
		_flashing_hovered_object = CursorManager.current_hovered_object
		var resource = CursorManager.current_hovered_object as RTS_Resource_Base
		var building = CursorManager.current_hovered_object as Building
		if resource != null:
			for u in SelectionHandler.selected_units:
				u.gather_resource(resource)
		elif building != null:
			if !building._built:
				for u in SelectionHandler.selected_units:
					u.build(building)
			else:
				for u in SelectionHandler.selected_units:
					u.order_deposit_resources(building)
	else:
		var group_guid = 0
		if len(SelectionHandler.selected_units) > 1:
			group_guid = UnitManager.add_group(SelectionHandler.selected_units.duplicate())
		for u in SelectionHandler.selected_units:
			if u.group_guid != null:
				UnitManager.leave_group(u)
			if len(SelectionHandler.selected_units) > 1:
				print()
				u.group_guid = group_guid
			u.order_move(get_global_mouse_position(), enums.e_order_type.move)
		if group_guid != 0:
			DebugDraw2d.circle(UnitManager.get_group_average_position(group_guid), 10, 16, Color(1, 0, 1), 1, 5)

func build(building) -> void:
	for u in SelectionHandler.selected_units:
		u.build(building)

func free() -> void:
	InputManager.right_click.disconnect(_order)
	super()




