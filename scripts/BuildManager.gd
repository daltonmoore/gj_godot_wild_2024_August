extends Node2D

var is_valid_build_location := false
var can_afford_to_place_building := false

var _current_ghost = null : set = set_ghost, get = get_ghost
var _current_real
var real_instance
var _press_time
var _selection_grid : SelectionGrid


func _ready() -> void:
	InputManager.left_click_pressed.connect(_press)
	InputManager.left_click_released.connect(place_building)
	InputManager.right_click_released.connect(cancel_building_placement)
	InputManager.mouse_move.connect(_snap_ghost)
	#GlobalTileMap.current_hovered_tile_changed.connect(_snap_ghost)
	_selection_grid = get_node("/root/main/SelectionGrid")

func set_ghost(ghost) -> void:
	if _current_ghost != null:
		_current_ghost.queue_free()
	_current_ghost = ghost

func get_ghost() -> Node2D:
	return _current_ghost


func set_real(real) -> void:
	_current_real = real

func _press(event) -> void:
	_press_time = Time.get_unix_time_from_system()
	if _current_real != null:
		real_instance = _current_real.instantiate()
		can_afford_to_place_building = real_instance.can_afford_to_build()


func _snap_ghost(event) -> void:
	if _current_ghost == null:
		return
	
	var mouse_local = get_local_mouse_position()
	var snapped_local = Vector2(int(mouse_local.x / 100) * 100,
			 int(mouse_local.y / 100) * 100) + Vector2(50,50)
	_current_ghost.position = snapped_local


func place_building(event) -> void:
	var _release_time = Time.get_unix_time_from_system()
	if (_current_ghost == null or
			_release_time - _press_time > .2 or
			!is_valid_build_location or 
			!can_afford_to_place_building):
		return
	
	spend_resources()
	
	get_tree().get_root().add_child(real_instance)
	real_instance.position = _current_ghost.position
	set_ghost(null)
	CommandManager.build(real_instance)
	var block = Polygon2D.new()
	block.polygon = real_instance.building_corners
	block.position = real_instance.position
	real_instance.building_nav_mesh_blocker = block
	get_tree().get_root().get_node("/root/main/NavigationRegion2D").add_child(block)
	(get_tree().get_root().get_node("/root/main/NavigationRegion2D") as NavigationRegion2D).bake_navigation_polygon()

func spend_resources() -> void:
	ResourceManager._spend_resources(real_instance.cost)

func cancel_building_placement(event) -> void:
	set_ghost(null)
