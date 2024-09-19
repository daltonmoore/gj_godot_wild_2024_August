extends Node2D

@export var resource_type : enums.e_resource_type

func _ready() -> void:
	pass


func _process(delta: float) -> void:
	pass


func _on_mouse_entered() -> void:
	CursorManager.set_current_hovered_resource(get_path())


func _on_mouse_exited() -> void:
	if CursorManager.current_hovered_resource.get_path() == get_path():
		CursorManager.current_hovered_resource = null
