extends Node2D

## This class is to manage issuing commands to selected units. Chop tree, attack 
## enemy, etc.

var _flashes = 5
var _current_flash_count = 0
var _flash_rate = .25

func _ready() -> void:
	z_index = Globals.background_z_index
	$ResourceSelectedFlashTimer.timeout.connect(_on_resource_selected_flash_timer_timeout)
	$ResourceSelectedFlashTimer.wait_time = _flash_rate

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Right Click"):
		if SelectionHandler.selected_units != null:
			if CursorManager.cursor_over_resource():
				# collect resource
				_current_flash_count = 0
				$ResourceSelectedFlashTimer.stop()
				$ResourceSelectedSquare.position = CursorManager.current_hovered_resource.position
				$ResourceSelectedSquare.visible = true
				$ResourceSelectedFlashTimer.start()
				var resource = CursorManager.current_hovered_resource
				for u in SelectionHandler.selected_units:
					u.gather_resource(resource)
			else:
				for u in SelectionHandler.selected_units:
					u.order_move()


func _on_resource_selected_flash_timer_timeout():
	$ResourceSelectedSquare.visible = not $ResourceSelectedSquare.visible
	_current_flash_count += 1
	
	if _current_flash_count >= _flashes:
		$ResourceSelectedSquare.visible = false
		$ResourceSelectedFlashTimer.stop()
