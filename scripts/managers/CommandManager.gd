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

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if _flash_on and _flashing_hovered_object != null:
		var pos = _flashing_hovered_object.position
		draw_rect(
			Rect2(pos - _flashing_hovered_object.visual_size / 2, _flashing_hovered_object.visual_size),
			Color.WEB_GREEN,
			false,
			2)

func _order(_event) -> void:
	if SelectionHandler.selected_units != null and len(SelectionHandler.selected_units) > 0:
		_order_units()

func _on_resource_selected_flash_timer_timeout():
	_flash_on = not _flash_on
	_current_flash_count += 1
	
	if _current_flash_count >= _flashes:
		_flash_on = false
		$SelectedFlashTimer.stop()

func _order_units() -> void:
	var first_selected_unit = SelectionHandler.selected_units[0]
	if (BuildManager.get_ghost() != null or 
			(first_selected_unit != null and 
			!first_selected_unit.is_queued_for_deletion() and 
			first_selected_unit.team == enums.e_team.enemy)
	):
		return
	
	if CursorManager.cursor_over_neutral_or_friendly_selectable():
		_handle_gather_build_deposit()
	else:
		_handle_move_attack()

func _handle_gather_build_deposit() -> void:
	# collect resource
	_current_flash_count = 0
	$SelectedFlashTimer.stop()
	$SelectedFlashTimer.start()
	_flash_on = true
	_flashing_hovered_object = CursorManager.current_hovered_inanimate_object
	var resource := CursorManager.current_hovered_inanimate_object as RTS_Resource_Base
	var building := CursorManager.current_hovered_inanimate_object as Building
	
	for unit in SelectionHandler.selected_units:
		var worker = unit as Worker
		
		if worker == null:
			continue
		
		if resource != null:
			worker.order_gather_resource(resource)
		elif building != null:
			if !building.built:
				worker.build(building)
			else:
				worker.order_deposit_resources(building)

func _handle_move_attack() -> void:
	for u in SelectionHandler.selected_units:
		if u == null:
			continue
		if CursorManager.cursor_over_enemy():
			u.order_attack(CursorManager.current_attackable)
			#if SelectionHandler.mouse_hovered_unit != null:
				#u.order_attack(SelectionHandler.mouse_hovered_unit)
			#else:
				#print("Is a enemy building")
				#u.order_attack(CursorManager.current_hovered_inanimate_object)

func build(building) -> void:
	for u in SelectionHandler.selected_units:
		u.build(building)

func free() -> void:
	InputManager.right_click.disconnect(_order)
	super()
