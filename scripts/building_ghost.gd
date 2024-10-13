extends Area2D

var blockers = []

func _ready() -> void:
	$Sprite2D.self_modulate = Color.GREEN
	BuildManager.is_valid_build_location = true

func _on_area_entered(area: Area2D) -> void:
	if (area.is_in_group("BlockConstruction")):
		blockers.append(area)
		$Sprite2D.self_modulate = Color.RED
		BuildManager.is_valid_build_location = false


func _on_area_exited(area: Area2D) -> void:
	if (area.is_in_group("BlockConstruction")):
		blockers.remove_at(blockers.bsearch(area))
		if len(blockers) == 0:
			$Sprite2D.self_modulate = Color.GREEN
			BuildManager.is_valid_build_location = true
