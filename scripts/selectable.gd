class_name Selectable
extends Node2D

var object_type := enums.e_object_type.none
var visual_size := Vector2.ZERO
var cursor_texture

func _on_mouse_entered() -> void:
	CursorManager.set_current_hovered_object(self)


func _on_mouse_exited() -> void:
	if CursorManager.current_hovered_object == self:
		CursorManager.set_current_hovered_object(null)
		
