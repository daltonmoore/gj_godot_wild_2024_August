extends TextureButton
@export var scene_building_ghost : PackedScene
@export var scene_building_real : PackedScene

func _ready() -> void:
	# Owner is always set to the scene's root node
	button_down.connect(_on_button_down.bind())
	button_up.connect(_on_button_up.bind())

func _on_button_down() -> void:
	print()
	
func _on_button_up() -> void:
	var _local_building_scene: Node = scene_building_ghost.instantiate()
	get_tree().get_root().add_child(_local_building_scene)
	_local_building_scene.modulate = Color(.5,.5,.5,.5)
	BuildManager.set_ghost(_local_building_scene)
	BuildManager.set_real(scene_building_real)
