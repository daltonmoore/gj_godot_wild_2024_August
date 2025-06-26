class_name Selectable
extends Node2D

var cursor_texture
var details
var in_selection := false
var object_type := enums.e_object_type.none
@export var team:= enums.e_team.none
var visual_size := Vector2.ZERO

func _on_mouse_entered() -> void:
	CursorManager.set_current_hovered_object(self)


func _on_mouse_exited() -> void:
	if CursorManager.current_hovered_inanimate_object == self:
		CursorManager.set_current_hovered_object(null)
		

func set_selection_circle_visible(value) -> void:
	$"Selection Circle".visible = value
