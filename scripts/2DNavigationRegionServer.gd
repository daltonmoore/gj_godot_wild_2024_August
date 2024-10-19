extends Node2D
@export var line : Line2D

var _bake_first_frame = true

func _process(delta: float) -> void:
	if _bake_first_frame:
		_bake_first_frame = false
		(get_node(".") as NavigationRegion2D).bake_navigation_polygon()

func _on_worker_path_changed(path: Variant) -> void:
	line.points = path
