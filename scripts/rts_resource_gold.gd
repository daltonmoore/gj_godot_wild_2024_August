extends RTS_Resource_Base

var _b_occupied := false
var _queue := []

func _ready() -> void:
	super()
	cursor_texture = load("res://art/cursors/mmorpg-cursorpack-Narehop/gold-pointer/pointer_62.png")
	resource_type = enums.e_resource_type.gold

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


#TODO: When a unit goes into the mine, they probably should be removed from selection list
func gather(unit : Unit) -> bool:
	super(unit)
	if _b_occupied:
		_queue.push_back(unit)
		unit.stop_gathering.disconnect(_on_unit_stop_gathering)
		return false
	
	unit.visible = false
	_set_occupied(true)
	#sig_can_gather.emit(unit)
	return true


func _on_unit_stop_gathering(unit: Unit) -> void:
	super(unit)
	unit.visible = true
	var u = _queue.pop_front()
	_set_occupied(false)
	#TODO: May be an issue when two units are waiting for this signal maybe	
	sig_can_gather.emit(u)


func _set_occupied(occupied):
	_b_occupied = occupied
	$OccupiedSprite.visible = occupied
	$VacantSprite.visible = !occupied
	
