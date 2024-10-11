extends Node2D

var _current_ghost = null : set = set_ghost, get = get_ghost
var _press_time
var _selection_grid : SelectionGrid

func _ready() -> void:
	InputManager.left_click_pressed.connect(_press)
	InputManager.left_click_released.connect(place_building)
	InputManager.mouse_move.connect(_snap_ghost)
	#GlobalTileMap.current_hovered_tile_changed.connect(_snap_ghost)
	_selection_grid = get_node("/root/main/SelectionGrid")

func set_ghost(ghost) -> void:
	_current_ghost = ghost

func get_ghost() -> Node2D:
	return _current_ghost


func _press(event) -> void:
	_press_time = Time.get_unix_time_from_system()


func _snap_ghost(event) -> void:
	if _current_ghost == null:
		return
	
	var mouse_local = get_local_mouse_position()
	var snapped_local = Vector2(int(mouse_local.x / 100) * 100,
			 int(mouse_local.y / 100) * 100) + Vector2(50,50)
	_current_ghost.position = snapped_local



func place_building(event) -> void:
	var _release_time = Time.get_unix_time_from_system()
	print (_release_time - _press_time)
	if _current_ghost == null or _release_time - _press_time > .2:
		return
	
	_current_ghost = null
