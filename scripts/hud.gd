extends CanvasLayer

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
	$Root/SelectedUnitInfo/UnitPicture.texture = null
	
	if new_selection != null and len(new_selection) == 1:
		$Root/SelectedUnitInfo/SelectedObjectName.text = new_selection[0].name
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
				$Root/SelectedUnitInfo/UnitPicture.texture = load(detail)
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



