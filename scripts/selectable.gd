class_name Selectable
extends Node2D

@export var object_type := enums.e_object_type.none
var visual_size := Vector2.ZERO

func _init() -> void:
	self.visual_size = visual_size

func _on_mouse_entered() -> void:
	CursorManager.set_current_hovered_object(self, object_type)


func _on_mouse_exited() -> void:
	if CursorManager.current_hovered_object == self:
		CursorManager.set_current_hovered_object(null, object_type)
		
