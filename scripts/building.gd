class_name Building
extends Selectable

# you know, when you are attempting to place a building and it is slightly
# transparent.
var is_ghost := false

func _ready() -> void:
	cursor_texture = load("res://art/cursors/mmorpg-cursorpack-Narehop/gold-pointer/pointer_8.png")
	object_type = enums.e_object_type.building
	visual_size = $Visual/Area2D/CollisionShape2D.shape.size


func set_is_ghost(in_is_ghost : bool) -> void:
	is_ghost = in_is_ghost


func _on_mouse_entered() -> void:
	if (!is_ghost):
		super()


func _on_mouse_exited() -> void:
	if (!is_ghost):
		super()

