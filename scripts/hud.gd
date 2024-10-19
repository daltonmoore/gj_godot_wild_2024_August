extends CanvasLayer

@onready var unit_pic = $Root/SelectedUnitInfo/UnitPicture
@onready var info_box = $Root/SelectedUnitInfo/InfoBox
@onready var supply_texture_rect = $Root/ResourceContainer/SupplyTextureRect

var unit_current_build_h_box : HBoxContainer
var unit_build_progress_bar : ProgressBar
var unit_build_queue_container : HFlowContainer
var _old_selection_first_item

func _ready() -> void:
	SelectionHandler.selection_changed.connect(update_selection)
	info_box.mouse_entered.connect(_mouse_entered_ui_element.bind(info_box))

func ___debug_button_pressed(button, zero) -> void:
	print("button pressed %s" % button.name)
	print(zero)

func update_resource(resource_type : enums.e_resource_type, amount : int) -> void:
	match resource_type:
		enums.e_resource_type.wood:
			$Root/ResourceContainer/WoodAmount.text = str(amount)
		enums.e_resource_type.gold:
			$Root/ResourceContainer/GoldAmount.text = str(amount)
		enums.e_resource_type.meat:
			$Root/ResourceContainer/MeatAmount.text = str(amount)
		enums.e_resource_type.supply:
			$Root/ResourceContainer/SupplyAmount.text = str(amount) + "/" + str(ResourceManager.supply_cap)
		enums.e_resource_type.supply_cap:
			$Root/ResourceContainer/SupplyAmount.text = str(ResourceManager.supply) + "/" + str(amount)

func update_selection(new_selection : Array) -> void:
	if SelectionHandler.mouse_hovered_ui_element != null:
		return
	
	for child in info_box.get_children():
		info_box.remove_child(child)
		child.queue_free()
	
	if _old_selection_first_item is Building:
		_handle_building_signal_disconnects(_old_selection_first_item)
	
	if new_selection == null or new_selection.size() == 0:
		_old_selection_first_item = null
	elif _old_selection_first_item != new_selection[0]:
		_old_selection_first_item = new_selection[0]
	
	if new_selection != null and len(new_selection) == 1:
		_handle_details(new_selection)
		
		# deal with the build queue and progress bar for the building
		if new_selection[0] is Building:
			_setup_build_queue(new_selection)
			_update_build_queue(new_selection[0]._build_queue)
			
			if !new_selection[0].is_currently_building():
				unit_current_build_h_box.visible = false
			else:
				unit_current_build_h_box.visible = true
		
		$Root/SelectedUnitInfo/SelectedObjectName.text = new_selection[0].name
		if new_selection[0] is Worker:
			$Root/BuilderMenu.visible = true
			$Root/BuildingMenu.visible = false
		elif new_selection[0] is Building:
			$Root/BuilderMenu.visible = false
			$Root/BuildingMenu.visible = true
	else:
		unit_pic.texture = null
		$Root/SelectedUnitInfo/SelectedObjectName.text = "None"
		$Root/BuilderMenu.visible = false
		$Root/BuildingMenu.visible = false

func supply_blocked() -> void:
	_flash_ui_element(supply_texture_rect)

func _flash_ui_element(ui_element) -> void:
	for n in 5:
		ui_element.modulate = Color.RED
		await get_tree().create_timer(.2).timeout
		supply_texture_rect.modulate = Color.WHITE
		await get_tree().create_timer(.2).timeout

func _handle_details(new_selection) -> void:
	for detail in new_selection[0].details:
		if detail is String:
			unit_pic.texture = load(detail)
			unit_pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			unit_pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			unit_pic.size = Vector2(64, 64)
		elif detail is UI_Detail:
			var h_box = HBoxContainer.new()
			var pic = TextureRect.new()
			pic.texture = load(detail.image_one_path)
			pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			pic.custom_minimum_size = Vector2(24, 24)
			h_box.add_child(pic)
			
			var label = Label.new()
			label.text = str(detail.detail_one)
			h_box.add_child(label)
			
			info_box.add_child(h_box)

func _update_unit_build_progress_bar(new_value, max_value, build_queue) -> void:
	unit_current_build_h_box.visible = true
	if unit_build_progress_bar != null:
		unit_build_progress_bar.max_value = max_value
		unit_build_progress_bar.value = new_value
	
	#if (unit_build_pic != null and 
			#(unit_build_pic.texture == null or 
			#unit_build_pic.texture.resource_path != build_queue[0].image_path)):
		#unit_build_pic.texture = load(build_queue[0].image_path)

func _on_build_queue_updated(build_queue) -> void:
	if unit_build_queue_container != null:
		for child in unit_build_queue_container.get_children():
			unit_build_queue_container.remove_child(child)
			child.queue_free()
	
	for child in unit_current_build_h_box.get_children():
		if child is TextureButton:
			unit_current_build_h_box.remove_child(child)
			child.queue_free()
	
	_update_build_queue(build_queue)

func _setup_build_queue(new_selection) -> void:
	new_selection[0].update_unit_build_progress.connect(_update_unit_build_progress_bar)
	unit_current_build_h_box = _construct_currently_building_ui(new_selection[0]._build_queue, new_selection[0])
	unit_current_build_h_box.name = "UnitBuildHbox"
	info_box.add_child(unit_current_build_h_box)
	
	unit_build_queue_container = HFlowContainer.new()
	unit_build_queue_container.name = "UnitBuildQueueContainer"
	info_box.add_child(unit_build_queue_container)

func _update_build_queue(build_queue):
	for i in len(build_queue):
		var build_item = build_queue[i]
		var queued_unit_btn = _construct_unit_texture_button(build_item)
		
		if i == 0:
			unit_current_build_h_box.add_child(queued_unit_btn)
			unit_current_build_h_box.move_child(queued_unit_btn, 0)
			queued_unit_btn.custom_minimum_size = Vector2(32,32)
		else:
			unit_build_queue_container.add_child(queued_unit_btn)

func _construct_currently_building_ui(build_queue, current_building) -> HBoxContainer:
	var currently_building_h_box = HBoxContainer.new()
	unit_build_progress_bar = ProgressBar.new()
	unit_build_progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	current_building.sig_unit_build_queue_finished.connect(_hide_unit_build_h_box_bar)
	current_building.sig_build_queue_updated.connect(_on_build_queue_updated)
	currently_building_h_box.visible = true
	currently_building_h_box.add_child(unit_build_progress_bar)
	return currently_building_h_box

func _construct_unit_texture_button(build_item) -> TextureButton:
	var texture = load(build_item.image_path)
	var btn = TextureButton.new()
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	btn.ignore_texture_size = true
	btn.custom_minimum_size = Vector2(16, 16)
	btn.texture_normal = texture
	btn.texture_pressed = texture
	btn.mouse_entered.connect(_mouse_entered_ui_element.bind(btn))
	btn.pressed.connect(_cancel_build_queue_item.bind(btn, build_item))
	
	return btn

func _hide_unit_build_h_box_bar() -> void:
	unit_current_build_h_box.visible = false

func _mouse_entered_ui_element(ui_element) -> void:
	if ui_element is TextureButton:
		SelectionHandler.mouse_hovered_ui_element = ui_element
	else:
		SelectionHandler.mouse_hovered_ui_element = null

func _cancel_build_queue_item(button, build_item) -> void:
	SelectionHandler._current_selected_object.cancel_build_item(build_item)
	unit_build_queue_container.remove_child(button)
	button.queue_free()

func _handle_building_signal_disconnects(building) -> void:
	building.sig_build_queue_updated.disconnect(_on_build_queue_updated)
	building.update_unit_build_progress.disconnect(_update_unit_build_progress_bar)
	building.sig_unit_build_queue_finished.disconnect(_hide_unit_build_h_box_bar)
