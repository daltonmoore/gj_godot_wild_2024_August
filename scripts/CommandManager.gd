extends Node2D

## This class is to manage issuing commands to selected units. Chop tree, attack 
## enemy, etc.

var _flashes = 5
var _current_flash_count = 0
var _flash_rate = .25
var _flash_on = false

func _ready() -> void:
	z_index = Globals.background_z_index
	$ResourceSelectedFlashTimer.timeout.connect(_on_resource_selected_flash_timer_timeout)
	$ResourceSelectedFlashTimer.wait_time = _flash_rate

func _process(delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if _flash_on:
		var pos = CursorManager.current_hovered_object.position
		draw_rect(
			Rect2(pos, CursorManager.current_hovered_object.visual_size),
			Color.WEB_GREEN,
			false)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Right Click"):
		if SelectionHandler.selected_units != null:
			if CursorManager.cursor_over_selectable():
				# collect resource
				_current_flash_count = 0
				$ResourceSelectedFlashTimer.stop()
				$ResourceSelectedSquare.position = CursorManager.current_hovered_object.position
				$ResourceSelectedSquare.visible = true
				_flash_on = true
				$ResourceSelectedFlashTimer.start()
				var resource = CursorManager.current_hovered_resource
				if resource != null:
					for u in SelectionHandler.selected_units:
						u.gather_resource(resource)
			else:
				for u in SelectionHandler.selected_units:
					u.order_move()


func _on_resource_selected_flash_timer_timeout():
	$ResourceSelectedSquare.visible = not $ResourceSelectedSquare.visible
	_flash_on = $ResourceSelectedSquare.visible
	_current_flash_count += 1
	
	if _current_flash_count >= _flashes:
		$ResourceSelectedSquare.visible = false
		$ResourceSelectedFlashTimer.stop()
