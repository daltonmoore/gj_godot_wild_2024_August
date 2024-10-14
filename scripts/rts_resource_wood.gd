class_name RTS_Resource_Base_Wood
extends RTS_Resource_Base

var _nav_mesh_blocker
var _nav_region : NavigationRegion2D

func _ready() -> void:
	super()
	_nav_region = get_tree().get_root().get_node("/root/main/NavigationRegion2D") as NavigationRegion2D
	z_index = 0
	$TopSprite.z_index = Globals.foreground_z_index
	$BotSprite.z_index = Globals.background_z_index
	$DamagedTimer.timeout.connect(_on_damaged_timer_timeout)
	
	cursor_texture = load("res://art/cursors/mmorpg-cursorpack-Narehop/gold-pointer/pointer_36.png")
	resource_type = enums.e_resource_type.wood
	visual_size = Vector2(50,50)
	
	var block = Polygon2D.new()
	var rect_size = $StaticBody2D/CollisionShape2D.shape.size
	block.polygon = [Vector2(-rect_size.x/2, -rect_size.y/2),
			Vector2(rect_size.x/2, -rect_size.y/2),
			Vector2(rect_size.x/2, rect_size.y/2),
			Vector2(-rect_size.x/2, rect_size.y/2)]
	block.position = to_global($StaticBody2D/CollisionShape2D.position)
	_nav_mesh_blocker = block
	_nav_region.add_child(block)


func gather(worker : Worker) -> bool:
	super(worker)
	$DamagedTimer.start()
	sig_can_gather.emit(worker)
	
	return true

func _input(event: InputEvent) -> void:
	if event.is_action("ui_accept") and event.is_pressed():
		$TopSprite.visible = !$TopSprite.visible

func _on_worker_stop_gathering(worker: Worker) -> void:
	super(worker)
	$DamagedTimer.stop()

func _destroy() -> void:
	_nav_mesh_blocker.queue_free()
	await get_tree().process_frame # just wait for the free to happen by next frame
	_nav_region.bake_navigation_polygon()
	super()

func _on_damaged_timer_timeout():
	if $BotSprite.visible:
		$TopSprite.visible = false
		$BotSprite.visible = false
		$DamagedSprite.visible = true
		$Area2D/DefaultCollisionShape2D.set_deferred("disabled", true)
		$Area2D/DamagedCollisionShape2D.set_deferred("disabled", false)

