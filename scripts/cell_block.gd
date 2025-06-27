class_name CellBlock
extends Node2D

var shape_size : Vector2

var _is_blocking_cell := false
var _nav_mesh_block : Polygon2D

func _init(parent, size = Vector2(15, 10)) -> void:
	name = "CellBlock"
	shape_size = size
	parent.add_child(self)

func block_cell() -> void:
	assert (NavHandler != null)
	_is_blocking_cell = true
	
	_nav_mesh_block = Polygon2D.new()
	var half_x = shape_size.x / 2
	var half_y = shape_size.y / 2
	_nav_mesh_block.polygon = PackedVector2Array(
		[
			Vector2(-half_x, -half_y),
			Vector2(-half_x, half_y),
			Vector2(half_x, half_y),
			Vector2(half_x, -half_y),
		]
	)
	DebugDraw2d.rect(global_position, shape_size, Color.RED, 1, 5)
	_nav_mesh_block.position = global_position
	NavHandler.update_obstacle(self, _nav_mesh_block, 
		func():
			print("I am callable")
	)

func unblock_cell() -> void:
	_is_blocking_cell = false
	_nav_mesh_block.polygon = PackedVector2Array([])
	NavHandler.update_obstacle(self, _nav_mesh_block, 
	func():
		print("I don't use this callable but i'll keep it for now")
	)
