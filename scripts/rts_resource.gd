class_name RTS_Resource
extends Node2D

@export var resource_type : enums.e_resource_type

func _ready() -> void:
	#TODO: 	units walk in front of upper part of tree. 
	#		need to split sprite to have different z-index for top and bottom
	z_index = Globals.foreground_z_index


func _process(delta: float) -> void:
	pass


func _on_mouse_entered() -> void:
	CursorManager.set_current_hovered_resource(get_path())


func _on_mouse_exited() -> void:
	if CursorManager.current_hovered_resource.get_path() == get_path():
		CursorManager.current_hovered_resource = null


#TODO: I think AOE2 does this by number of hits maybe? Could just stop the timer if gathering ceases
func gather(unit : Unit) -> void:
	ResourceManager.add_resource_gatherer(unit, self)
	get_tree().create_timer(1).timeout.connect(
		func():
			if $Sprite.visible:
				$Sprite.visible = false
				$DamagedSprite.visible = true
	)
	
