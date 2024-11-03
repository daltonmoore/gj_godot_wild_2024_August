class_name Attackable
extends Node2D

#region Signals
signal sig_dying(this)
#endregion

#region Export
@export var health : float = 50.0
@export var hurt_sounds : Array[AudioStream] = []
@export var max_health : float = 50.0
#endregion

#region Public Vars
var team:= enums.e_team.none
#endregion

#region Private Vars
var _corpse_scene := load("res://scenes/corpse.tscn")
var _cursor_texture
var _in_selection := false
var _is_dying := false
var _sprite = null
#endregion

#region OnReady

@onready var health_bar: ProgressBar = $"../HealthBar"
#endregion

func _ready() -> void:
	sig_dying.connect(_on_self_die)
	_setup_health_bar()
	# sword for attack
	_cursor_texture = load("res://art/cursors/mmorpg-cursorpack-Narehop/gold-pointer/pointer_23.png")
	
	if owner is Building or owner is EnemyBuilding:
		_sprite = owner.get_node("Sprite2D")
		_corpse_scene = load("res://scenes/buildings/building_rubble.tscn")
	else:
		_sprite = owner.get_node("AnimatedSprite2D")

func set_in_selection(val) -> void:
	_in_selection = val

func get_is_dying() -> bool:
	return _is_dying

func take_damage(incoming_damage: float) -> void:
	if _is_dying:
		return
	
	Util.create_one_shot_audio_stream("hurt_audio_stream", hurt_sounds, self)
	
	health -= incoming_damage
	health_bar.value = health
	if health <= 0:
		_die()

func _die() -> void:
	var instance = _corpse_scene.instantiate()
	get_tree().get_root().add_child(instance)
	instance.position = global_position
	_is_dying = true
	sig_dying.emit(self)

func _on_mouse_entered() -> void:
	CursorManager.set_current_attackable(self)

func _on_mouse_exited() -> void:
	if CursorManager.current_attackable == self:
		CursorManager.set_current_attackable(null)

func _on_self_die(_me) -> void:
	_sprite.visible = false
	if _in_selection:
		SelectionHandler.remove_from_selection(owner)
	owner.queue_free()

func _setup_health_bar() -> void:
	if health_bar == null: 
		return
	
	health_bar.max_value = max_health
	health_bar.value = max_health
	health_bar.position = Vector2(-50, -100)
	health_bar.add_theme_font_size_override(&"font_size", 1)
	health_bar.show_percentage = false
	health_bar.size = Vector2(100, 5)
	health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var _health_bar_style_box = StyleBoxFlat.new()
	_health_bar_style_box.bg_color = Color.RED
	health_bar.add_theme_stylebox_override(&"fill", _health_bar_style_box)
