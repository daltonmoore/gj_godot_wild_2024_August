class_name Enemy
extends Unit

func _ready() -> void:
	super()
	vision_area.body_entered.connect(_on_vision_area_body_entered)
	vision_area.body_exited.connect(_on_vision_area_body_exited)

func _physics_process(delta: float) -> void:
	super(delta)
	
	if (_targetted_enemy != null and 
			vision_area.overlaps_body(_targetted_enemy) and
			!_is_attacking):
		set_movement_target(_targetted_enemy.global_position)

func _on_vision_area_body_entered(body) -> void:
	if _targetted_enemy == null and body is CharacterBody2D:
		order_attack(body)

func _on_vision_area_body_exited(body) -> void:
	if body == _targetted_enemy:
		_stop_attacking()
