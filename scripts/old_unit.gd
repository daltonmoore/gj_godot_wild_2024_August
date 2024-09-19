class_name old_Unit
extends CharacterBody2D


# 05. signals
# 06. enums
# 07. constants
# 08. @export variables
# 09. public variables
# 10. private variables
# 11. @onready variables

const SPEED = 100.0

# export vars
@export_group("My Properties")
@export var damage: int = 10

var current_anim = "idle"
var is_chasing = false
var target: Player
var is_player_in_weapon_range
var move_to_pos

#region Built In Methods

func _ready() -> void:
	move_to_pos = position


func _physics_process(delta: float) -> void:
	if current_anim != $AnimatedSprite2D.animation:
		$AnimatedSprite2D.play(current_anim)
	
	if is_chasing and false:
		position = position.move_toward(target.position, delta * SPEED)
		# get dot to target to determine enemy facing
		var enemy_to_target = position.direction_to(target.position)
		var enemy_facing_dot = enemy_to_target.dot(Vector2.RIGHT)
		if enemy_facing_dot > 0:
			# enemy's target is on the right
			$AnimatedSprite2D.flip_h = true
		else:
			$AnimatedSprite2D.flip_h = false
		
		DebugDraw2d.arrow_vector(position, Vector2.RIGHT*40)
		
		# Facing vector
		#DebugDraw2d.arrow_vector(position, 
				#Vector2.RIGHT.rotated($WeaponPivot.rotation)*100, 
				#Color.BLACK)
				
		$WeaponPivot.look_at(target.position)
		
		DebugDraw2d.arrow_vector(Vector2.ZERO,position)
		#DebugDraw2d.arrow_vector(Vector2.ZERO,target.position)
		
		move_and_collide(enemy_to_target * delta)
	
	# mouse movement for testing
	# from A to B = B - A
	if move_to_pos != null and !position.is_equal_approx(move_to_pos):
		velocity = position.direction_to(move_to_pos) * SPEED
		DebugDraw2d.arrow_vector(Vector2.ZERO,move_to_pos)
		#DebugDraw2d.circle(move_to_pos)
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()
	
	
func _draw() -> void:
	#draw_circle(move_to_pos, 20, Color.RED)
	pass


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Click"):
		# idk if assuming this event can be cast to InputEventMouse is bad
		#move_to_pos = (event as InputEventMouse).position
		move_to_pos = get_global_mouse_position()
		

#endregion


# PRIVATE METHODS
func _do_damage() -> void:
	$WeaponTimer.start(1.0)
	target.receive_damage(damage)


#region SIGNALS
func _on_wake_trigger_body_entered(body: Node2D) -> void:
	if body is Player and !is_chasing:
		# Wake up!!
		current_anim = "ceiling_out"
		target = body as Player


func _on_chase_radius_body_exited(body: Node2D) -> void:
	if body is Player and is_chasing:
		current_anim = "ceiling_in"
		is_chasing = false
		target = null


func _on_animated_sprite_2d_animation_finished() -> void:
	if current_anim == "ceiling_out":
		current_anim = "flying"
		# Start chasing the target
		is_chasing = true
	elif current_anim == "ceiling_in":
		current_anim = "idle"


func _on_animated_sprite_2d_animation_changed() -> void:
	pass


func _on_weapon_trigger_body_entered(body: Node2D) -> void:
	if body is Player and $WeaponTimer.is_stopped():
		target = body as Player
		_do_damage()
		is_player_in_weapon_range = true


func _on_weapon_trigger_body_exited(body: Node2D) -> void:
	if body is Player:
		is_player_in_weapon_range = false


func _on_weapon_timer_timeout() -> void:
	if is_player_in_weapon_range:
		_do_damage()
	else:
		$WeaponTimer.stop()
	pass # Replace with function body.
#endregion




