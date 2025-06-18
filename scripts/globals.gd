extends Node2D

const debug: bool = false
const max_audio_stream_distance: float = 1000.0
const unit_group: String = "units"
const top_z_index: int        = 10
const foreground_z_index: int = 4
const default_z_index: int    = 3
const building_z_index: int   = 2
const background_z_index: int = 1
const tile_map_layer_background: int = 0
const tile_map_layer_foreground: int = 1
const tile_map_custom_data_layer_selectable: String = "Selectable"
const tile_map_custom_data_layer_type: String       = "Type" # Type of tile such as: Wood, Gold etc.

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
