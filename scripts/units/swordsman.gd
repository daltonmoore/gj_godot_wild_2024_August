class_name Swordsman
extends Unit

func order_move(in_goal, in_order_type := enums.e_order_type.none, silent := false) -> void:
	super(in_goal, in_order_type, silent)
	

func order_attack(enemy):
	super(enemy)
	

func _on_navigation_finished() -> void:
	super()
