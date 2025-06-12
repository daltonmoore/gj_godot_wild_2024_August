extends Node2D

signal sig_supply_free

var starting_gold := 1000
var starting_wood := 1000
var starting_meat := 1000
var gold : float
var wood : float
var meat : float
var supply : int
var supply_cap : int
var _supply_blocked : bool = false

func _ready() -> void:
	_update_resource(starting_gold, enums.e_resource_type.gold)
	_update_resource(starting_wood, enums.e_resource_type.wood)
	_update_resource(starting_meat, enums.e_resource_type.meat)


func _process(_delta: float) -> void:
	if _supply_blocked and supply < supply_cap:
		sig_supply_free.emit()
		_supply_blocked = false

func _spend_resources(cost) -> void:
	for c in cost:
		if c != enums.e_resource_type.supply:
			_update_resource(-cost[c], c)

func _peek_can_afford_supply(supply_cost) -> bool:
	return supply + supply_cost <= supply_cap

func _update_resource(amount : int, type : enums.e_resource_type):
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
			if supply >= supply_cap:
				#print("Supply blocked!! Supply Cap is %s" % supply_cap)
				_supply_blocked = true
		enums.e_resource_type.supply_cap:
			supply_cap += amount
			changed_value = supply_cap
	
	Hud.update_resource(type, changed_value)
