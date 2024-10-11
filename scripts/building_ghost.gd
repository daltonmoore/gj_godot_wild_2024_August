extends Area2D


func _on_area_entered(area: Area2D) -> void:
	print(area)
	if (area.is_in_group("BlockConstruction")):
		$Sprite2D.self_modulate = Color.RED


func _on_area_exited(area: Area2D) -> void:
	print(area)
	if (area.is_in_group("BlockConstruction")):
		$Sprite2D.self_modulate = Color.GREEN
