extends TabButton
@export var packed_scene_building : PackedScene


func _on_button_down() -> void:
	print()
	
func _on_button_up() -> void:
	var _local_building_scene = packed_scene_building.instantiate()
	#_local_building_scene.set_is_ghost(true)
	
	get_tree().get_root().add_child(_local_building_scene)
	
	BuildManager.set_ghost(_local_building_scene)
