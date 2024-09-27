extends CanvasLayer

func _ready() -> void:
	SelectionHandler.selection_changed.connect(update_selection)

func update_wood(amount):
	assert (amount is float or amount is int)
	$HBoxContainer/WoodAmount.text = floori(amount)


func update_selection(new_selection):
	if new_selection != null and len(new_selection) > 0:
		$SelectedObjectName.text = new_selection[0].name
	else:
		$SelectedObjectName.text = "None"
