extends CanvasLayer

@onready var unit_pic = $Root/SelectedUnitInfo/UnitPicture

var unit_build_progress_bar : ProgressBar
var _old_selection_first_item

func _ready() -> void:
	SelectionHandler.selection_changed.connect(update_selection)


func update_resource(resource_type : enums.e_resource_type, amount : int):
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


func update_selection(new_selection : Array):
	var info_box = $Root/SelectedUnitInfo/InfoBox
	for child in info_box.get_children():
		info_box.remove_child(child)
		child.queue_free()
	
	unit_pic.texture = null
	
	if new_selection == null or new_selection.size() == 0:
		if _old_selection_first_item is Building:
			_old_selection_first_item.sig_start_building_unit.disconnect(_building_started)
			_old_selection_first_item.update_unit_build_progress.disconnect(_update_detail_progress_bar)
		_old_selection_first_item = null
	elif _old_selection_first_item != new_selection[0]:
		if _old_selection_first_item is Building:
			_old_selection_first_item.sig_start_building_unit.disconnect(_building_started)
			_old_selection_first_item.update_unit_build_progress.disconnect(_update_detail_progress_bar)
		_old_selection_first_item = new_selection[0]
	
	if new_selection != null and len(new_selection) == 1:
		$Root/SelectedUnitInfo/SelectedObjectName.text = new_selection[0].name
		if new_selection[0] is Building:
			new_selection[0].sig_start_building_unit.connect(_building_started)
		for detail in new_selection[0].details:
			if detail is UI_Detail:
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
			elif detail is String:
				unit_pic.texture = load(detail)
				unit_pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				unit_pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if new_selection[0] is Worker:
			$Root/BuilderMenu.visible = true
			$Root/BuildingMenu.visible = false
		elif new_selection[0] is Building:
			$Root/BuilderMenu.visible = false
			$Root/BuildingMenu.visible = true
	else:
		$Root/SelectedUnitInfo/SelectedObjectName.text = "None"
		$Root/BuilderMenu.visible = false
		$Root/BuildingMenu.visible = false

func _building_started(detail) -> void:
	var info_box = $Root/SelectedUnitInfo/InfoBox
	var h_box = HBoxContainer.new()
	var pic = TextureRect.new()
	
	pic.texture = load(detail.image_one_path)
	pic.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	unit_build_progress_bar = ProgressBar.new()
	unit_build_progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if !SelectionHandler._current_selected_object.update_unit_build_progress.is_connected(_update_detail_progress_bar):
		SelectionHandler._current_selected_object.update_unit_build_progress.connect(_update_detail_progress_bar)
	unit_build_progress_bar.position += Vector2(50,0)
	
	h_box.add_child(pic)
	h_box.add_child(unit_build_progress_bar)
	info_box.add_child(h_box)

func _update_detail_progress_bar(new_value, max_value) -> void:
	if unit_build_progress_bar != null:
		unit_build_progress_bar.max_value = max_value
		unit_build_progress_bar.value = new_value

