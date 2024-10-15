class_name Unit
extends CharacterBody2D

@export var movement_speed: float = 4.0
@export var cost : Dictionary = {"Gold": 0.0,"Wood": 0.0,"Meat": 0.0, "Supply": 1}

var details
var group_guid

# Public Vars
var current_cell: SelectionGridCell:
	get:
		return current_cell
	set(value):
		current_cell = value

# Private Vars
var _current_cell_label
var _current_order_type : enums.e_order_type
var _in_selection := false

@onready var navigation_agent: NavigationAgent2D = get_node("NavigationAgent2D")

func _ready() -> void:
	navigation_agent.debug_enabled = Globals.debug
	ResourceManager._add_resource(cost["Supply"], enums.e_resource_type.supply)
	# Debug name text
	var label = Label.new()
	label.text = "%s" % name
	add_child(label)
	label.position = Vector2(0, -100) # is relative pos
	
	# debug current cell text
	_current_cell_label = Label.new()
	add_child(_current_cell_label)
	_current_cell_label.position = Vector2(0, 25) # is relative pos
	add_to_group(Globals.unit_group)
	navigation_agent.velocity_computed.connect(Callable(_on_velocity_computed))
	$Area2D.mouse_entered.connect(on_mouse_overlap)
	$Area2D.mouse_exited.connect(on_mouse_exit)
	z_index = Globals.unit_z_index
	
	var ui_detail_one = UI_Detail.new()
	ui_detail_one.image_one_path = "res://art/icons/RPG Graphics Pack - Icons/Pack 1A-Renamed/boot/boot_03.png"
	ui_detail_one.detail_one = movement_speed
	var unit_picture_path = "res://art/Tiny Swords (Update 010)/Factions/Knights/Troops/Pawn/Blue/Pawn_Blue-still.png"
	details = [ui_detail_one, unit_picture_path]


func set_movement_target(movement_target: Vector2):
	navigation_agent.set_target_position(movement_target)

func set_selection_circle_visible(visible):
	$"Selection Circle".visible = visible

func _physics_process(delta: float) -> void:
	var next_path_position: Vector2 = navigation_agent.get_next_path_position()
	var new_velocity: Vector2 = global_position.direction_to(next_path_position) * movement_speed
	
	if navigation_agent.avoidance_enabled:
		navigation_agent.set_velocity(new_velocity)
	else:
		_on_velocity_computed(new_velocity)
	
	if new_velocity.dot(Vector2.RIGHT) < 0:
		$AnimatedSprite2D.flip_h = true
	else:
		$AnimatedSprite2D.flip_h = false
	
	#if current_cell == null

func _on_velocity_computed(safe_velocity: Vector2):
	velocity = safe_velocity
	move_and_slide()

func order_move(in_goal, in_order_type : enums.e_order_type):
	set_movement_target(in_goal)

func stop() -> void:
	set_movement_target(position)

func on_mouse_overlap():
	SelectionHandler.mouse_hovered_unit = self

func on_mouse_exit():
	if SelectionHandler.mouse_hovered_unit == self:
		SelectionHandler.mouse_hovered_unit = null

func can_afford_to_build() -> bool:
	var can_afford = true
	for r in cost:
		match r:
			"Gold":
				if ResourceManager.gold < cost[r]:
					can_afford = false
					break
			"Wood":
				if ResourceManager.wood < cost[r]:
					can_afford = false
					break
			"Meat":
				if ResourceManager.meat < cost[r]:
					can_afford = false
					break
			"Suply":
				if ResourceManager.supply_cap < cost[r] + ResourceManager.supply:
					can_afford = false
					break
	
	return can_afford

func _on_navigation_finished() -> void:
	if _in_selection and !UnitManager.group_stopping:
		UnitManager.group_stopping = true
		_find_close_in_group_units_and_stop_them()


func _find_close_in_group_units_and_stop_them() -> void:
	for a in $SearchAreaSmall.get_overlapping_areas():
		if a.owner == null:
			continue
		if a.owner.is_in_group(Globals.unit_group):
			var unit = a.owner as Unit
			if UnitManager.groups.has(group_guid) and unit.group_guid == group_guid:
				unit.stop()
	UnitManager.group_stopping = false


