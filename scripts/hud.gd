extends CanvasLayer

func _ready() -> void:
	SelectionHandler.selection_changed.connect(update_selection)
	
	#var tw=create_tween().bind_node(simple_build_btn).set_loops(-1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	#tw.tween_property(simple_build_btn,"scale",Vector2(1.2,1.2),2).from(Vector2.ONE)
	#tw.tween_property(simple_build_btn,"scale",Vector2.ONE,2)
	

func update_resource(resource_type : enums.e_resource_type, amount : int):
	match resource_type:
		enums.e_resource_type.wood:
			$Root/ResourceContainer/WoodAmount.text = str(floori(($Root/ResourceContainer/WoodAmount.text as int) + amount))
		enums.e_resource_type.gold:
			$Root/ResourceContainer/WoodAmount.text = str(floori(($Root/ResourceContainer/WoodAmount.text as int) + amount))


func update_selection(new_selection):
	if new_selection != null and len(new_selection) > 0:
		$Root/SelectedObjectName.text = new_selection[0].name
	else:
		$Root/SelectedObjectName.text = "None"



