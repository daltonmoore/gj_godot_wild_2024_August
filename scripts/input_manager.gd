extends Node2D

signal left_click_pressed(event)
signal left_click_released(event)
signal right_click_pressed(event)
signal right_click_released(event)
signal mouse_move(event)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				left_click_pressed.emit(event)
			elif event.is_released():
				left_click_released.emit(event)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if event.is_pressed():
				right_click_pressed.emit(event)
			elif event.is_released():
				right_click_released.emit(event)
	elif event is InputEventMouseMotion:
		mouse_move.emit(event)
