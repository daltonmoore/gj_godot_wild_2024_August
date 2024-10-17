class_name Building
extends Selectable

signal finish_building
signal update_unit_build_progress(new_value)

@export var construction_sprite : CompressedTexture2D
@export var destroyed_sprite : CompressedTexture2D
@export var built_sprite : CompressedTexture2D
@export var total_build_time : float
@export var building_corners : PackedVector2Array
@export var cost : Dictionary = {"Gold": 0.0,"Wood": 0.0,"Meat": 0.0}
@export var _built := false
@export var armor := 5
@export var building_type := enums.e_building_type.none
@export var supply_cap := 0
@export var default_rally_point_location := Vector2.ZERO

var building_nav_mesh_blocker
var rally_point

var _build_queue : Array
var _current_build_time := 0.0
var _current_unit_build_time := 0.0
var _default_cursor = load("res://art/cursors/mmorpg-cursorpack-Narehop/gold-pointer/pointer_8.png")
var _construction_cursor_texture = load("res://art/cursors/mmorpg-cursorpack-Narehop/gold-pointer/pointer_37.png")



func _ready() -> void:
	rally_point = Node2D.new()
	add_child(rally_point)
	rally_point.position = default_rally_point_location
	if _built:
		ResourceManager._add_resource(supply_cap, enums.e_resource_type.supply_cap)
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
	
	var ui_detail_one = UI_Detail.new()
	ui_detail_one.image_one_path = "res://art/icons/RPG Graphics Pack - Icons/Pack 1A/armor/armor_09.png"
	ui_detail_one.detail_one = armor
	
	var ui_detail_build_queue = UI_Detail.new()
	ui_detail_build_queue.image_one_path = "res://art/icons/RPG Graphics Pack - Icons/Pack 1A-Renamed/weapon/weapon_sword_07.png"
	ui_detail_build_queue.detail_one = ProgressBar.new()
	
	var building_picture_path = ""
	match building_type:
		enums.e_building_type.townhall:
			building_picture_path = "res://art/Tiny Swords (Update 010)/Factions/Knights/Buildings/Castle/Castle_Blue-export.png"
	details = [ui_detail_one, building_picture_path, ui_detail_build_queue]

func _process(delta: float) -> void:
	
	if !$UnitBuildTimer.is_stopped():
		_current_unit_build_time += delta
		update_unit_build_progress.emit(_current_unit_build_time)
	
	if !$BuildTimer.is_stopped() and !$BuildTimer.paused:
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

func queue_build_unit(purchase_type : enums.e_purchase_type) -> void:
	var unit_to_build
	match purchase_type:
		enums.e_purchase_type.worker:
			unit_to_build = load("res://scenes/worker.tscn")
	_build_queue.push_back(unit_to_build)
	start_building_unit()

# given a point, get a random point on the perimeter of the rectangle on either the top
# side or bottom side whichever is closer to given point
func get_random_point_along_perimeter(pos) -> Vector2:
	var half_y = $Visual/Area2D/CollisionShape2D.shape.size.y / 2
	var half_x = $Visual/Area2D/CollisionShape2D.shape.size.x / 2
	var rand_x = randi_range(-half_x, half_x)
	var bot_edge_point = Vector2(rand_x, half_y)
	var top_edge_point = Vector2(rand_x, -half_y)
	if pos.distance_to(top_edge_point) < pos.distance_to(bot_edge_point):
		DebugDraw2d.circle(top_edge_point + position, 10,  16, Color(1, 0, 1), 1, 4)
		return to_global(top_edge_point)
	DebugDraw2d.circle(bot_edge_point + position, 10,  16, Color(1, 0, 1), 1, 4)
	return to_global(bot_edge_point) 

func start_building_unit() -> void:
	if $UnitBuildTimer.is_stopped():
		_current_unit_build_time = 0.0
		$UnitBuildTimer.start()

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


func get_rally_point_position() -> Vector2:
	return to_global(rally_point.position)
