class_name Building
extends Selectable

func _ready() -> void:
	cursor_texture = load("res://art/cursors/mmorpg-cursorpack-Narehop/gold-pointer/pointer_8.png")
	object_type = enums.e_object_type.building
	visual_size = $Visual/Area2D/CollisionShape2D.shape.size
