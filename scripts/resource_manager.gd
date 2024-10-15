extends Node2D

@export var starting_gold := 200
@export var starting_wood := 200
@export var starting_meat := 200

var gold : float
var wood : float
var meat : float
var supply : int
var supply_cap : int

func _ready() -> void:
	_add_resource(starting_gold, enums.e_resource_type.gold)
	_add_resource(starting_wood, enums.e_resource_type.wood)
	_add_resource(starting_meat, enums.e_resource_type.meat)

func _add_resource(amount : float, type : enums.e_resource_type):
	if type == enums.e_resource_type.none:
		return
	
	var changed_value = 0
	match type:
		enums.e_resource_type.gold:
			gold += amount
			changed_value = gold
		enums.e_resource_type.wood:
			wood += amount
			changed_value = wood
		enums.e_resource_type.meat:
			meat += amount
			changed_value = meat
		enums.e_resource_type.supply:
			supply += amount
			changed_value = supply
		enums.e_resource_type.supply_cap:
			supply_cap += amount
			changed_value = supply_cap
	
	Hud.update_resource(type, changed_value)

