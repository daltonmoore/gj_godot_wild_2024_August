class_name RTS_Resource_Base
extends Selectable

signal sig_can_gather(worker)
signal exhausted

@export_range(1, 5000) var resource_amount := 100.0
@export var _gather_area_start_position := Vector2.ZERO

var resource_type : enums.e_resource_type
var amtlabel = Label.new()
var _cell_block: CellBlock
var _remaining_amount_progress_bar : ProgressBar = ProgressBar.new()
var _gather_area = Area2D.new()
var _gather_circle = CollisionShape2D.new()
var _random_idle_anim_start_frame: int


func _ready() -> void:
	z_index = Globals.default_z_index
	team = enums.e_team.neutral
	add_child(amtlabel)
	amtlabel.position = Vector2(0, -20) # is relative pos
	object_type = enums.e_object_type.resource
	
	_remaining_amount_progress_bar.visible = false
	_remaining_amount_progress_bar.show_percentage = false
	_remaining_amount_progress_bar.max_value = resource_amount
	_remaining_amount_progress_bar.value = resource_amount
	_remaining_amount_progress_bar.size = Vector2(100, 10)
	_remaining_amount_progress_bar.position = Vector2(-50, -100)
	add_child(_remaining_amount_progress_bar)
	
	_gather_circle.shape = CircleShape2D.new()
	_gather_circle.shape.radius = 30
	_gather_area.add_child(_gather_circle)
	_gather_area.position = _gather_area_start_position
	add_child(_gather_area)


func _process(_delta: float) -> void:
	amtlabel.text = str(resource_amount)

func take(amount : int) -> float:
	var given_amount := 0
	if amount > resource_amount:
		given_amount = resource_amount
		resource_amount = 0
	else:
		resource_amount -= amount
		given_amount = amount
	
	if resource_amount == 0:
		exhausted.emit()
		_destroy()
	_remaining_amount_progress_bar.value = resource_amount
	_remaining_amount_progress_bar.visible = true
	return given_amount

func get_random_gather_point() -> Vector2:
	# x = cx + r * cos a
	var radius = _gather_circle.shape.radius
	var rand_x = radius * cos(randf_range(0, 2*PI))
	var rand_y = radius * sin(randf_range(0, 2*PI))
	var random_point_on_circle = Vector2(rand_x, rand_y)
	DebugDraw2d.circle(to_global(random_point_on_circle + _gather_area.position), 10,  16, Color(1, 0, 1), 1, 4)
	
	return to_global(random_point_on_circle + _gather_area.position)

func gather(worker : Worker) -> bool:
	worker.stop_gathering.connect(_on_worker_stop_gathering)
	
	return true


func _destroy() -> void:
	for conn in self.get_incoming_connections():
		conn.signal.disconnect(conn.callable)
	queue_free()

func _on_worker_stop_gathering(worker: Worker) -> void:
	worker.stop_gathering.disconnect(_on_worker_stop_gathering)
