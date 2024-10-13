class_name TabButton
extends TextureButton

@export var target_tab : int = 0
@export var tab_group : TabContainer

func _ready() -> void:
	# Owner is always set to the scene's root node
	button_down.connect(_on_button_down.bind())
	button_up.connect(_on_button_up.bind())


func _on_button_down() -> void:
	self.get_parent().scale *= 1.1


func _on_button_up() -> void:
	self.get_parent().scale /= 1.1
	tab_group.current_tab = target_tab
	
