extends CanvasLayer

func update_wood(amount):
	assert (amount is float or amount is int)
	$HBoxContainer/WoodAmount.text = floori(amount)
