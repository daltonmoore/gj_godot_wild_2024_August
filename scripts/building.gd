class_name Building
extends Selectable

func _ready() -> void:
	object_type = enums.e_object_type.building
	visual_size = $Visual/Area2D/CollisionShape2D.shape.size
