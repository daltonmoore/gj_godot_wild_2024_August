extends Node2D

const debug = false

const unit_group = "units"

const top_z_index = 10
const foreground_z_index = 3
const unit_z_index = 2
const background_z_index = 1

const tile_map_layer_background = 0
const tile_map_layer_foreground = 1

const tile_map_custom_data_layer_selectable = "Selectable"
const tile_map_custom_data_layer_type = "Type" # Type of tile such as: Wood, Gold etc.

static func arrays_have_same_content(a1 : Array, a2: Array) -> bool:
	if a1.size() != a2.size():
		return false
	return false
#TODO: finish this method
	#for item in a1:
#

static func has_pattern(pattern: String, string : String) -> bool:
	var regex = RegEx.new()
	regex.compile(pattern)
	var result = regex.search(string)
	return result != null
