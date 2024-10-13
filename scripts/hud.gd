extends CanvasLayer

func _ready() -> void:
	SelectionHandler.selection_changed.connect(update_selection)


func update_resource(resource_type : enums.e_resource_type, amount : int):
	match resource_type:
		enums.e_resource_type.wood:
			$Root/ResourceContainer/WoodAmount.text = str(floori(($Root/ResourceContainer/WoodAmount.text as int) + amount))
		enums.e_resource_type.gold:
			$Root/ResourceContainer/WoodAmount.text = str(floori(($Root/ResourceContainer/WoodAmount.text as int) + amount))


func update_selection(new_selection : Array):
	if new_selection != null and len(new_selection) > 0:
		$Root/SelectedObjectName.text = new_selection[0].name
		if new_selection[0] is Worker:
			$Root/BuilderMenu.visible = true
	else:
		$Root/SelectedObjectName.text = "None"
		$Root/BuilderMenu.visible = false



