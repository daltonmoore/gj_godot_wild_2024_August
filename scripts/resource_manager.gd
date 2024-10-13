extends Node2D

var gold : float
var wood : float
var meat : float

func _add_resource(amount : float, type : enums.e_resource_type):
	if amount <= 0 or type == enums.e_resource_type.none:
		return
	
	match type:
		enums.e_resource_type.gold:
			gold += amount
		enums.e_resource_type.wood:
			wood += amount
		enums.e_resource_type.meat:
			meat += amount

func _spend_resource(amount : float, type : enums.e_resource_type):
	pass
