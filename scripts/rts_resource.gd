class_name RTS_Resource
extends Selectable

@export var resource_type : enums.e_resource_type

var _damaged_timer
var _wood_count := 0

func _ready() -> void:
	#TODO: 	units walk in front of upper part of tree. 
	#		need to split sprite to have different z-index for top and bottom
	z_index = Globals.foreground_z_index
	$DamagedTimer.timeout.connect(_on_damaged_timer_timeout)
	
	object_type = enums.e_object_type.resource
	visual_size = Vector2(50,50)


#TODO: I think AOE2 does this by number of hits maybe? Could just stop the timer if gathering ceases
func gather(unit : Unit) -> void:
	ResourceManager.add_resource_gatherer(unit, self)
	unit.stop_gathering.connect(_on_unit_stop_gathering)
	$DamagedTimer.start()


func _on_damaged_timer_timeout():
	if $Sprite.visible:
		$Sprite.visible = false
		$DamagedSprite.visible = true
		$Area2D/DefaultCollisionShape2D.set_deferred("disabled", true)
		$Area2D/DamagedCollisionShape2D.set_deferred("disabled", false)

#TODO: make sure this works for multiple workers
func _on_unit_stop_gathering(unit: Unit) -> void:
	$DamagedTimer.stop()
	unit.stop_gathering.disconnect(_on_unit_stop_gathering)
