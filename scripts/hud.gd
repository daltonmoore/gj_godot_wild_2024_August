extends CanvasLayer

func _ready() -> void:
	SelectionHandler.selection_changed.connect(update_selection)

func update_resource(resource_type : enums.e_resource_type, amount : int):
	match resource_type:
		enums.e_resource_type.wood:
			$HBoxContainer/WoodAmount.text = str(floori(($HBoxContainer/WoodAmount.text as int) + amount))
		enums.e_resource_type.gold:
			$HBoxContainer/WoodAmount.text = str(floori(($HBoxContainer/WoodAmount.text as int) + amount))


func update_selection(new_selection):
	if new_selection != null and len(new_selection) > 0:
		$SelectedObjectName.text = new_selection[0].name
	else:
		$SelectedObjectName.text = "None"
