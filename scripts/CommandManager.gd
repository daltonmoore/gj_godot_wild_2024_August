extends Node2D

## This class is to manage issuing commands to selected units. Chop tree, attack 
## enemy, etc.

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Right Click"):
		if SelectionHandler.selected_units != null:
			# what did we click on??
			#
			for u in SelectionHandler.selected_units:
				u.order_move()
