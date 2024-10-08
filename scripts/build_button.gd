extends TabButton
@export var packed_scene_building : PackedScene

var _player_camera

func _on_button_down() -> void:
	print("i am a build button pushed down")
	
func _on_button_up() -> void:
	var _local_building_scene = packed_scene_building.instantiate()
	_local_building_scene.set_is_ghost(true)
	get_tree().get_root().add_child(_local_building_scene)
	
	if _player_camera == null:
		_player_camera = get_viewport().get_camera_2d()
	
	if _player_camera != null:
		_player_camera.set_ghost_placement(_local_building_scene)
