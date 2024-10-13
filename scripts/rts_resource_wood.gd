class_name RTS_Resource_Base_Wood
extends RTS_Resource_Base

func _ready() -> void:
	super()
	#TODO: 	workers walk in front of upper part of tree. 
	#		need to split sprite to have different z-index for top and bottom
	$DamagedTimer.timeout.connect(_on_damaged_timer_timeout)
	
	cursor_texture = load("res://art/cursors/mmorpg-cursorpack-Narehop/gold-pointer/pointer_36.png")
	resource_type = enums.e_resource_type.wood
	visual_size = Vector2(50,50)


#TODO: I think AOE2 does this by number of hits maybe? Could just stop the timer if gathering ceases
func gather(worker : Worker) -> bool:
	super(worker)
	$DamagedTimer.start()
	sig_can_gather.emit(worker)
	
	return true

func _on_worker_stop_gathering(worker: Worker) -> void:
	super(worker)
	$DamagedTimer.stop()


func _on_damaged_timer_timeout():
	if $Sprite.visible:
		$Sprite.visible = false
		$DamagedSprite.visible = true
		$Area2D/DefaultCollisionShape2D.set_deferred("disabled", true)
		$Area2D/DamagedCollisionShape2D.set_deferred("disabled", false)

