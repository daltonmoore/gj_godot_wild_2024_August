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


#TODO: When a worker goes into the mine, they probably should be removed from selection list
func gather(worker : Worker) -> bool:
	super(worker)
	if _b_occupied:
		_queue.push_back(worker)
		worker.stop_gathering.disconnect(_on_worker_stop_gathering)
		return false
	
	worker.visible = false
	_set_occupied(true)
	#sig_can_gather.emit(worker)
	return true


func _on_worker_stop_gathering(worker: Worker) -> void:
	super(worker)
	worker.visible = true
	var u = _queue.pop_front()
	_set_occupied(false)
	#TODO: May be an issue when two workers are waiting for this signal maybe	
	sig_can_gather.emit(u)


func _set_occupied(occupied):
	_b_occupied = occupied
	$OccupiedSprite.visible = occupied
	$VacantSprite.visible = !occupied
	
