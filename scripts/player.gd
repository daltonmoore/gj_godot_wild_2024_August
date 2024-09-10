class_name Player
extends CharacterBody2D

signal health_changed

const SPEED = 500.0
const JUMP_VELOCITY = -400.0

# export vars
@export_group("My Properties")
@export var default_health: int = 100
@export var wounded_sounds : Array[AudioStream]

# private vars begin with underscore
# Is private!!!
var _health = default_health

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity")


func _physics_process(delta: float) -> void:
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var horz_direction := Input.get_axis("Left", "Right")
	var vert_direction := Input.get_axis("Up", "Down")
	if horz_direction:
		velocity.x = horz_direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	if vert_direction:
		velocity.y = vert_direction * SPEED
	else:
		velocity.y = move_toward(velocity.x, 0, SPEED)
		
	if $Sprite2D.modulate != Color(1, 1, 1):
		print("getting back to normal")
		var hitColor = $Sprite2D.modulate
		hitColor.r = move_toward(hitColor.r, 1, delta)
		hitColor.b = move_toward(hitColor.b, 1, delta)
		hitColor.g = move_toward(hitColor.g, 1, delta)
		$Sprite2D.modulate = hitColor
		
	move_and_slide()


func receive_damage(damage: float) -> void:
	health_changed.emit()
	_health -= damage
	$Sprite2D.modulate = Color(1, 0, 0)
	$WoundedSound.stream = wounded_sounds.pick_random()
	$WoundedSound.play()
	
	
func get_current_health() -> int:
	return _health
