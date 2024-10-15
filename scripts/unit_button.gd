extends TextureButton

@export var unit_to_build : PackedScene

func _ready() -> void:
	# Owner is always set to the scene's root node
	button_down.connect(_on_button_down.bind())
	button_up.connect(_on_button_up.bind())

func _on_button_down() -> void:
	print()
	
func _on_button_up() -> void:
	var _local_unit_scene = unit_to_build.instantiate()
	if _local_unit_scene.can_afford_to_build():
		get_tree().get_root().add_child(_local_unit_scene)
		_local_unit_scene.position = SelectionHandler._current_selected_object.get_rally_point_position()
