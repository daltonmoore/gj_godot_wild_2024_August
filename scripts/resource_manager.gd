# Resource Manager
extends Node2D

func add_resource_gatherer(gatherer : Unit, resource : RTS_Resource):
	print("Gatherer %s is gathering resource %s now" % [gatherer, resource])
