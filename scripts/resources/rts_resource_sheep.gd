class_name RTS_Resource_Sheep
extends RTS_Resource_Animated

var current_cell: SelectionGridCell:
	get: return current_cell
	set(value): current_cell = value

var _default_cursor = CursorManager.cursors[enums.E_CursorType.SELECT]

func _ready() -> void:
	super()
	cursor_texture = _default_cursor
	$Area2D.mouse_entered.connect(_on_mouse_entered)
	$Area2D.mouse_exited.connect(_on_mouse_exited)
	
