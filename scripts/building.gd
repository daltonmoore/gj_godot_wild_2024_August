class_name Building
extends Node2D

func _ready() -> void:
	await get_parent().ready
	get_parent().visual_size = $Visual/Area2D/CollisionShape2D.shape.size

