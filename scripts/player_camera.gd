class_name PlayerCamera
extends Camera2D

@export var camera_speed: float
@export var camera_bounds: Rect2

var _zoom_pos

func _ready() -> void:
	DebugDraw2d.rect(
			camera_bounds.position + camera_bounds.size/2,
			camera_bounds.size, 
			Color(1, 1, 1),
			3,
			INF)
	
	


func _physics_process(delta: float) -> void:
	var horz_direction := Input.get_axis("Left", "Right")
	var vert_direction := Input.get_axis("Up", "Down")
	position += Vector2(horz_direction * camera_speed * delta, 
			vert_direction * camera_speed * delta)
	position = position.clamp(Vector2.ZERO, camera_bounds.size)
	DebugDraw2d.circle(position)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed():
			# zoom in
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				_zoom_pos = get_global_mouse_position()
				# call the zoom function
				zoom *= 1.05
			# zoom out
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_zoom_pos = get_global_mouse_position()
				# call the zoom function
				zoom /= 1.05


