class_name SelectionGridCell
extends Area2D

var grid_index
var grid_pos
var _selection_grid

func _ready() -> void:
	_selection_grid = get_node("/root/main/SelectionGrid")

func _on_body_entered(body: Node2D) -> void:
	_selection_grid.cell_entered(self, body)


func _on_body_exited(body: Node2D) -> void:
	_selection_grid.cell_exited(self, body)
