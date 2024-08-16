extends CharacterBody2D


const SPEED = 50.0
const JUMP_VELOCITY = -400.0

var current_anim = "idle"
var is_chasing = false
var target: Player

func _physics_process(delta: float) -> void:
	if current_anim != $AnimatedSprite2D.animation:
		print("Changing anim from " + $AnimatedSprite2D.animation +" to " + current_anim)
		$AnimatedSprite2D.play(current_anim)
	
	if is_chasing:
		DebugDraw2d.arrow_vector(position, target.position - position)
		DebugDraw2d.circle(target.position)
		position = position.move_toward(target.position, delta * SPEED)
	
	move_and_slide()


func _on_wake_trigger_body_entered(body: Node2D) -> void:
	if body is Player and !is_chasing:
		# Wake up!!
		print("Waking!")
		current_anim = "ceiling_out"
		target = body as Player


func _on_chase_radius_body_exited(body: Node2D) -> void:
	if body is Player and is_chasing:
		current_anim = "ceiling_in"
		is_chasing = false
		target = null


func _on_animated_sprite_2d_animation_finished() -> void:
	print($AnimatedSprite2D.animation + " finished")
	if current_anim == "ceiling_out":
		current_anim = "flying"
		# Start chasing the target
		is_chasing = true
	elif current_anim == "ceiling_in":
		current_anim = "idle"


func _on_animated_sprite_2d_animation_changed() -> void:
	#print($AnimatedSprite2D.animation + " changed")
	pass
