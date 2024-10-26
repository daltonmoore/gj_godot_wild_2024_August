extends Node2D

var _death_audio_stream_player:= AudioStreamPlayer2D.new()

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	animated_sprite_2d.animation_finished.connect(_on_animation_finished)
	add_child(_death_audio_stream_player)
	_death_audio_stream_player.stream = load("res://sound/Orcs/Orc Death 1.mp3")
	_death_audio_stream_player.play()

func _on_animation_finished() -> void:
	if animated_sprite_2d.animation == &"die":
		await get_tree().create_timer(4).timeout
		animated_sprite_2d.play(&"buried")
		await get_tree().create_timer(4).timeout
		var tween = get_tree().create_tween()
		tween.tween_property($AnimatedSprite2D, "modulate", Color.RED, 1)
		tween.tween_property($AnimatedSprite2D, "scale", Vector2(), 1)
		tween.tween_callback(queue_free)
