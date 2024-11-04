class_name Building
extends Selectable

#region Signals
signal sig_build_queue_updated(build_queue)
signal sig_unit_build_queue_finished
signal finish_building
signal update_unit_build_progress(new_value, max_value, current_build_item)
#endregion

#region Export
@export var armor := 5
@export var building_corners : PackedVector2Array
@export var building_type := enums.e_building_type.none
@export var built_sprite : CompressedTexture2D
@export var build_times : Dictionary = {}
@export var built := false
@export var construction_sprite : CompressedTexture2D
## Gold is 2, Wood is 1, Meat is 3
@export var cost : Dictionary = {
	enums.e_resource_type.gold: 0.0,
	enums.e_resource_type.wood: 0.0,
	enums.e_resource_type.meat: 0.0
	}
@export var default_rally_point_location := Vector2.ZERO
@export var destroyed_sprite : CompressedTexture2D
@export var supply_cap := 0
@export var total_build_time : float
#endregion

#region Public
var building_nav_mesh_blocker
var rally_point
#endregion

#region Private
var _build_queue : Array
var _build_sound = load("res://sound/Jingles_Fanfares_SFX_Pack/Jingles_and_Fanfares/Quest/Quest_Accepted.wav")
var _building_audio_stream_player : AudioStreamPlayer2D
var _cell_block: CellBlock
var _construction_cursor_texture = load("res://art/cursors/mmorpg-cursorpack-Narehop/gold-pointer/pointer_37.png")
var _current_build_time := 0.0
var _current_unit_build_time := 0.0
var _default_cursor = load("res://art/cursors/mmorpg-cursorpack-Narehop/gold-pointer/pointer_8.png")
var _supply_blocked_audio_stream_player : AudioStreamPlayer2D
var _supply_blocked_sound = load("res://sound/Jingles_Fanfares_SFX_Pack/Jingles_and_Fanfares/Puzzle_Minigame/Failure.wav")
var _unit_build_timer = null
#endregion

#region Built-in Methods

func _ready() -> void:
	z_index = Globals.building_z_index
	_setup_audio_streams()
	_setup_rally_point()
	_setup_ui_details()
	_setup_visual()
	_setup_timers()
	
	await get_tree().process_frame
	_cell_block.block_cell()

func _process(delta: float) -> void:
	if _unit_build_timer != null and !_unit_build_timer.is_stopped():
		_current_unit_build_time += delta
		update_unit_build_progress.emit(
			_current_unit_build_time, 
			_build_queue[0].total_build_time,
			_build_queue)
	
	if !$BuildTimer.is_stopped() and !$BuildTimer.paused:
		_current_build_time += delta
	
	if !built:
		$ProgressBar.value = _current_build_time / total_build_time
#endregion

#region Public Methods
# can afford to build the building?
func can_afford_to_build() -> bool:
	var can_afford = true
	for r in cost:
		match r:
			enums.e_resource_type.gold:
				if ResourceManager.gold < cost[r]:
					can_afford = false
					break
			enums.e_resource_type.wood:
				if ResourceManager.wood < cost[r]:
					can_afford = false
					break
			enums.e_resource_type.meat:
				if ResourceManager.meat < cost[r]:
					can_afford = false
					break
	
	return can_afford

func cancel_build_item(item) -> void:
	var index = _build_queue.find(item)
	if index == 0:
		_unit_build_timer.stop()
	
	_build_queue.remove_at(index)
	sig_build_queue_updated.emit(_build_queue)
	if _build_queue.size() > 0:
		start_building_unit(_build_queue[0].purchase_type)
	else:
		sig_unit_build_queue_finished.emit()

func get_rally_point_position() -> Vector2:
	return to_global(rally_point.position)

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

func is_currently_building() -> bool:
	return _build_queue.size() > 0

func queue_build_unit(purchase_type : enums.e_purchase_type, local_unit_scene) -> void:
	ResourceManager._spend_resources(local_unit_scene.cost)
	var unit_to_build = build_item.new()
	unit_to_build.purchase_type = purchase_type
	unit_to_build.total_build_time = build_times[purchase_type]
	unit_to_build.supply_cost = local_unit_scene.cost[enums.e_resource_type.supply]
	match purchase_type:
		enums.e_purchase_type.worker:
			unit_to_build.scene = load("res://scenes/units/worker.tscn")
			unit_to_build.image_path = "res://art/Tiny Swords (Update 010)/Factions/Knights/Troops/Pawn/Blue/Pawn_Blue-still.png"
	_build_queue.push_back(unit_to_build)
	sig_build_queue_updated.emit(_build_queue)
	if _build_queue.size() == 1:
		start_building_unit(purchase_type)

func set_rally_point_position(_event) -> void:
	if $"Selection Circle".visible:
		rally_point.position = to_local(get_global_mouse_position())

func start_building_unit(purchase_type : enums.e_purchase_type) -> void:
	if _unit_build_timer.is_stopped():
		_current_unit_build_time = 0.0
		_unit_build_timer.wait_time = build_times[purchase_type]
		_unit_build_timer.start()

func start_building() -> void:
	if $BuildTimer.is_stopped():
		_current_build_time = 0.0
		$BuildTimer.start()
	elif $BuildTimer.paused:
		$BuildTimer.paused = false

func stop_building() -> void:
	$BuildTimer.paused = true
#endregion

#region Private Methods

func _setup_audio_streams() -> void:
	_supply_blocked_audio_stream_player = AudioStreamPlayer2D.new()
	_supply_blocked_audio_stream_player.stream = _supply_blocked_sound
	_supply_blocked_audio_stream_player.volume_db += 10
	add_child(_supply_blocked_audio_stream_player)
	_building_audio_stream_player = AudioStreamPlayer2D.new()
	_building_audio_stream_player.stream = _build_sound
	add_child(_building_audio_stream_player)

func _finish_building_unit() -> void:
	_unit_build_timer.stop()
	if !ResourceManager._peek_can_afford_supply(_build_queue[0].supply_cost):
		print("cannot afford supply of this unit. build more houses!!")
		Hud.supply_blocked()
		_supply_blocked_audio_stream_player.play()
		await ResourceManager.sig_supply_free
	_building_audio_stream_player.play()
	var unit = _build_queue.pop_front()
	var u = unit.scene.instantiate()
	get_tree().get_root().add_child(u)
	u.position = position
	u.order_move(get_rally_point_position(), enums.e_order_type.move, true)
	sig_build_queue_updated.emit(_build_queue)
	
	if _build_queue.size() > 0:
		start_building_unit(_build_queue[0].purchase_type)
	else:
		sig_unit_build_queue_finished.emit()

func _finish_building() -> void:
	$Visual.texture = built_sprite
	finish_building.emit()
	built = true
	$ProgressBar.visible = false
	cursor_texture = _default_cursor
	ResourceManager._update_resource(supply_cap, enums.e_resource_type.supply_cap)

func _setup_rally_point() -> void:
	InputManager.right_click_released.connect(set_rally_point_position)
	rally_point = Sprite2D.new()
	rally_point.texture = load("res://art/icons/RPG Graphics Pack - Icons/Pack 1A/shield/shield_09.png")
	add_child(rally_point)
	rally_point.position = default_rally_point_location

func _setup_timers() -> void:
	$BuildTimer.wait_time = total_build_time
	$BuildTimer.timeout.connect(_finish_building)
	if has_node("UnitBuildTimer"):
		_unit_build_timer = $UnitBuildTimer
		_unit_build_timer.timeout.connect(_finish_building_unit)

func _setup_ui_details() -> void:
	var ui_detail_one = UI_Detail.new()
	ui_detail_one.image_one_path = "res://art/icons/RPG Graphics Pack - Icons/Pack 1A/armor/armor_09.png"
	ui_detail_one.detail_one = armor
	
	var building_picture_path = ""
	match building_type:
		enums.e_building_type.townhall:
			building_picture_path = "res://art/Tiny Swords (Update 010)/Factions/Knights/Buildings/Castle/Castle_Blue-export.png"
	
	
	details = [ui_detail_one, building_picture_path]

func _setup_visual() -> void:
	if built:
		ResourceManager._update_resource(supply_cap, enums.e_resource_type.supply_cap)
		cursor_texture = _default_cursor
		$Visual.texture = built_sprite
		$ProgressBar.visible = false
	else:
		cursor_texture = _construction_cursor_texture
		$Visual.texture = construction_sprite
	visual_size = $Visual/Area2D/CollisionShape2D.shape.size
	_cell_block = CellBlock.new(self, visual_size)
	object_type = enums.e_object_type.building
#endregion

class build_item:
	var scene
	var purchase_type : enums.e_purchase_type
	var total_build_time := 5.0
	var supply_cost
	var image_path
