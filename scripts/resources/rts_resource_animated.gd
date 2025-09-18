class_name RTS_Resource_Animated
extends RTS_Resource_Base


func _ready() -> void:
	super()
	var animatedSprite := ($"../Sprite" as AnimatedSprite2D)
	_random_idle_anim_start_frame = randi_range(0, animatedSprite.sprite_frames.get_frame_count("idle"))
	animatedSprite.frame = _random_idle_anim_start_frame

	$DamagedTimer.timeout.connect(_on_damaged_timer_timeout)

	cursor_texture = load("res://art/cursors/mmorpg-cursorpack-Narehop/gold-pointer/pointer_36.png")
	resource_type = enums.e_resource_type.wood
	visual_size = Vector2(50,50)
	_cell_block = CellBlock.new(self, visual_size)

	var block = Polygon2D.new()
	var rect_size = $NavMeshBlockerStaticBody/CollisionShape2D.shape.size
	block.polygon = [Vector2(-rect_size.x/2, -rect_size.y/2),
	Vector2(rect_size.x/2, -rect_size.y/2),
	Vector2(rect_size.x/2, rect_size.y/2),
	Vector2(-rect_size.x/2, rect_size.y/2)]
	block.position = to_global($NavMeshBlockerStaticBody/CollisionShape2D.position)

	await get_tree().process_frame
	_cell_block.block_cell()


func gather(worker : Worker) -> bool:
	super(worker)
	$DamagedTimer.start()
	sig_can_gather.emit(worker)

	return true


func _on_worker_stop_gathering(worker: Worker) -> void:
	super(worker)
	$DamagedTimer.stop()

func _destroy() -> void:
	# TODO: fix this for procedural nav mesh stuff
	#_nav_mesh_blocker.queue_free()
	#await get_tree().process_frame # just wait for the free to happen by next frame
	#_nav_region.bake_navigation_polygon()
	super()

func _on_damaged_timer_timeout():
	if $Sprite.visible:
		$Sprite.visible = false
		$DamagedSprite.visible = true
		$Area2D/DefaultCollisionShape2D.set_deferred("disabled", true)
		$Area2D/DamagedCollisionShape2D.set_deferred("disabled", false)
