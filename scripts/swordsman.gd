extends Unit

func order_move(in_goal, in_order_type : enums.e_order_type, silent := false) -> void:
	super(in_goal, in_order_type, silent)
	

func order_attack(attackable):
	super(attackable)

func _on_navigation_finished() -> void:
	super()
	
