@tool
class_name UiDetails 
extends Node2D

@export var details: Array[UiDetail] = []
	
func _handle_details(new_selection, unit_pic, info_box) -> void:
	if new_selection[0]._details == null:
		return

	for detail in new_selection[0]._details:
		if detail is String:
			unit_pic.texture = load(detail)
			unit_pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			unit_pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			unit_pic.size = Vector2(64, 64)
		elif detail is UiDetail:
			var h_box = HBoxContainer.new()
			var pic = TextureRect.new()
			pic.texture = load(detail.image_one_path)
			pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			pic.custom_minimum_size = Vector2(24, 24)
			h_box.add_child(pic)

			var label = Label.new()
			label.text = str(detail.detail_one)
			h_box.add_child(label)

			info_box.add_child(h_box)
