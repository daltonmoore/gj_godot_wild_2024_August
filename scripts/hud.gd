extends CanvasLayer

func _ready() -> void:
	SelectionHandler.selection_changed.connect(update_selection)


func update_resource(resource_type : enums.e_resource_type, amount : int):
	match resource_type:
		enums.e_resource_type.wood:
			$Root/ResourceContainer/WoodAmount.text = str(floori(($Root/ResourceContainer/WoodAmount.text as int) + amount))
		enums.e_resource_type.gold:
			$Root/ResourceContainer/GoldAmount.text = str(floori(($Root/ResourceContainer/GoldAmount.text as int) + amount))


func update_selection(new_selection : Array):
	if new_selection != null and len(new_selection) > 0:
		$Root/SelectedUnitInfo/SelectedObjectName.text = new_selection[0].name
		var info_box = $Root/SelectedUnitInfo/InfoBox
		for child in info_box.get_children():
			info_box.remove_child(child)
			child.queue_free()
		for detail in new_selection[0].details:
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
		if new_selection[0] is Worker:
			$Root/BuilderMenu.visible = true
	else:
		$Root/SelectedUnitInfo/SelectedObjectName.text = "None"
		$Root/BuilderMenu.visible = false



