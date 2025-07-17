extends Node2D

signal mouse_over_object(object)



@export var cursors: Dictionary[enums.E_CursorType, Texture2D]

var current_attackable : Attackable
var current_hovered_tile : TileData
var current_hovered_inanimate_object : Selectable

var _current_cursor_type := enums.E_CursorType.DEFAULT

func _ready() -> void:
	#Input.mouse_mode = Input.MOUSE_MODE_CONFINED
	InputManager.mouse_move.connect(_mouse_move)
	for cursor_type in cursors.keys():
		set_cursor_scale(4, cursor_type)

func _mouse_move(event) -> void:
	if BuildManager._current_ghost != null:
		return
	
	# Updating cursor
	if SelectionHandler.mouse_hovered_unit != null:
		if cursor_over_enemy() and SelectionHandler.has_units_selected():
			Input.set_custom_mouse_cursor(cursors[enums.E_CursorType.ATTACK])
			_current_cursor_type = enums.E_CursorType.ATTACK
		else:
			Input.set_custom_mouse_cursor(cursors[enums.E_CursorType.SELECT])
			_current_cursor_type = enums.E_CursorType.SELECT
	else:
		Input.set_custom_mouse_cursor(cursors[enums.E_CursorType.DEFAULT])
		_current_cursor_type = enums.E_CursorType.DEFAULT
	
	if (current_hovered_inanimate_object == null):
		return
	
	match current_hovered_inanimate_object.object_type:
		enums.e_object_type.resource:
			# TODO: only have selected workers instead of any selected unit do this logic
			# we only want to display different cursors when we have units selected that can mine/gather the resources
			if (len(SelectionHandler.selected_things) > 0):
				Input.set_custom_mouse_cursor(current_hovered_inanimate_object.cursor_texture)
		_:
			Input.set_custom_mouse_cursor(current_hovered_inanimate_object.cursor_texture)
	

func cursor_over_anything() -> bool:
	return cursor_over_enemy() or cursor_over_resource() or cursor_over_selectable()

func cursor_over_selectable() -> bool:
	return current_hovered_inanimate_object != null

func cursor_over_neutral_or_friendly_selectable() -> bool:
	return (current_hovered_inanimate_object != null and 
		(current_hovered_inanimate_object.team == enums.e_team.player or 
		current_hovered_inanimate_object.team == enums.e_team.neutral))

func cursor_over_enemy() -> bool:
	return ((SelectionHandler.mouse_hovered_unit != null and SelectionHandler.mouse_hovered_unit.team == enums.e_team.enemy) or
		current_attackable != null)

func cursor_over_resource() -> bool:
	return current_hovered_inanimate_object is RTS_Resource_Base

func set_current_hovered_object(object):
	current_hovered_inanimate_object = object

func set_current_attackable(attackable):
	current_attackable = attackable
	
func set_cursor_scale(_scale: float, cursor_type: enums.E_CursorType ) -> void:
	var image: Image = cursors[cursor_type].get_image()
	# Pixel counts are integars, so we cast Vector2 (using float) to Vector2i (using int)
	var size := Vector2i(_scale * image.get_size())
	var scaled: Image = image.duplicate()
	# Resize the image with bilinear interpolation
	scaled.resize(size.x, size.y, Image.INTERPOLATE_NEAREST)
	
	cursors[cursor_type] = ImageTexture.create_from_image(scaled)
	
