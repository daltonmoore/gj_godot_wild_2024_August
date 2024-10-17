extends TextureButton

@export var unit_to_build : PackedScene
@export var purchase_type : enums.e_purchase_type

func _ready() -> void:
	# Owner is always set to the scene's root node
	button_down.connect(_on_button_down.bind())
	button_up.connect(_on_button_up.bind())

func _on_button_down() -> void:
	print()
	
func _on_button_up() -> void:
	var _local_unit_scene = unit_to_build.instantiate()
	if _local_unit_scene.can_afford_to_build():
		SelectionHandler._current_selected_object.queue_build_unit(purchase_type, _local_unit_scene)
		
