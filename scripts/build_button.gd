extends TabButton
@export var scene_building_ghost : PackedScene
@export var scene_building_real : PackedScene

func _on_button_down() -> void:
	print()
	
func _on_button_up() -> void:
	var _local_building_scene = scene_building_ghost.instantiate()
	get_tree().get_root().add_child(_local_building_scene)
	_local_building_scene.modulate = Color(.5,.5,.5,.5)
	BuildManager.set_ghost(_local_building_scene)
	BuildManager.set_real(scene_building_real)
