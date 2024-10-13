class_name Building
extends Selectable

signal finish_building

@export var construction_sprite : CompressedTexture2D
@export var destroyed_sprite : CompressedTexture2D
@export var built_sprite : CompressedTexture2D
@export var total_build_time : float
@export var building_corners : PackedVector2Array
@export var cost : Dictionary = {"Gold": 0.0,"Wood": 0.0,"Meat": 0.0}
@export var _built := false

var building_nav_mesh_blocker

var _current_build_time := 0.0
var _default_cursor = load("res://art/cursors/mmorpg-cursorpack-Narehop/gold-pointer/pointer_8.png")
var _construction_cursor_texture = load("res://art/cursors/mmorpg-cursorpack-Narehop/gold-pointer/pointer_37.png")



func _ready() -> void:
	if _built:
		cursor_texture = _default_cursor
		$Visual.texture = built_sprite
		$ProgressBar.visible = false
	else:
		cursor_texture = _construction_cursor_texture
		$Visual.texture = construction_sprite
	object_type = enums.e_object_type.building
	visual_size = $Visual/Area2D/CollisionShape2D.shape.size
	
	$BuildTimer.wait_time = total_build_time
	$BuildTimer.timeout.connect(_finish_building)

func _process(delta: float) -> void:
	if $BuildTimer.paused:
		return
	
	if !$BuildTimer.is_stopped():
		_current_build_time += delta
	
	if !_built:
		$ProgressBar.value = _current_build_time / total_build_time

func can_afford_to_build() -> bool:
	var can_afford = true
	for r in cost:
		match r:
			"Gold":
				if ResourceManager.gold < cost[r]:
					can_afford = false
					break
			"Wood":
				if ResourceManager.wood < cost[r]:
					can_afford = false
					break
			"Meat":
				if ResourceManager.meat < cost[r]:
					can_afford = false
					break
	
	return can_afford

func get_random_point_along_perimeter() -> Vector2:
	var half_y = $Visual/Area2D/CollisionShape2D.shape.size.y / 2
	var half_x = $Visual/Area2D/CollisionShape2D.shape.size.x / 2
	var rand_x = randi_range(-half_x, half_x)
	DebugDraw2d.circle(Vector2(rand_x, half_y) + position, 10,  16, Color(1, 0, 1), 1, 4)
	return Vector2(rand_x, half_y) + position

func start_building() -> void:
	if $BuildTimer.is_stopped():
		_current_build_time = 0.0	
		$BuildTimer.start()
	elif $BuildTimer.paused:
		$BuildTimer.paused = false

func stop_building() -> void:
	$BuildTimer.paused = true

func _finish_building() -> void:
	$Visual.texture = built_sprite
	finish_building.emit()
	_built = true
	$ProgressBar.visible = false
	cursor_texture = _default_cursor
