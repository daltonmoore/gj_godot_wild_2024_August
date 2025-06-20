class_name SelectionGridCell
extends Area2D

var grid_index
var grid_pos
var _selection_grid

func _ready() -> void:
	_selection_grid = get_node("/root/main/SelectionGrid")

func _on_body_entered(body: Node2D) -> void:
	var u = body as Unit
	if u == null:
		return
	
	if u.team == enums.e_team.player:
		if u._current_cell != null:
			_selection_grid.cell_exited(u._current_cell, body)
		_selection_grid.cell_entered(self, body)

	u._current_cell = self


#func _on_body_exited(body: Node2D) -> void:
	#var u = body as Unit
	#
	#if u != null:
		#_selection_grid.cell_exited(self, body)	
		#u.current_cell = null
