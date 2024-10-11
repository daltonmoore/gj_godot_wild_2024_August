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
	
	position = Vector2.ZERO
	get_parent().position = Vector2.ZERO
	


func _physics_process(delta: float) -> void:
	var horz_direction := Input.get_axis("Left", "Right")
	var vert_direction := Input.get_axis("Up", "Down")
	
	var viewport_rect = get_viewport().get_visible_rect()
	if (get_local_mouse_position().x > (viewport_rect.size.x / zoom.x / 2) - 20): # right boundary
		DebugDraw2d.circle(get_global_mouse_position(), 10, 16, Color.GREEN)
		horz_direction = 1
	elif (get_local_mouse_position().x < -(viewport_rect.size.x / zoom.x / 2) + 20): # left boundary
		DebugDraw2d.circle(get_global_mouse_position(), 10, 16, Color.GREEN)
		horz_direction = -1
	
	if (get_local_mouse_position().y > (viewport_rect.size.y / zoom.y / 2) - 20): # bottom boundary
		DebugDraw2d.circle(get_global_mouse_position(), 10, 16, Color.GREEN)
		vert_direction = 1
	elif (get_local_mouse_position().y < -(viewport_rect.size.y / zoom.y / 2) + 20): # top boundary
		DebugDraw2d.circle(get_global_mouse_position(), 10, 16, Color.GREEN)
		vert_direction = -1
	
	
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


