extends Unit
@onready var anim_sprite = $AnimatedSprite2D

func order_move(in_goal, in_order_type : enums.e_order_type, silent := false) -> void:
	super(in_goal, in_order_type, silent)
	anim_sprite.animation = "run"

func _on_navigation_finished() -> void:
	super()
	anim_sprite.animation = "idle"
