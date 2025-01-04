class_name RenderSettings extends Object

var blend_texture_size: Vector2i
var top_left_pos: Vector2i
var output_resolution: Vector2i
# <bottom cutoff index, vertical cutoff index>, inclusive
var vertical_cutoff: Vector2i
# used to determine size of circles
var max_index_size: float
var pixels_per_index: float 
var ant_per_index_size: float
var queen_per_index_size: float
var enemy_per_index_size: float
var food_per_index_size: float

func to_byte_array() -> PackedByteArray:
	var byte_array := PackedInt32Array([
		blend_texture_size.x, blend_texture_size.y, 
		top_left_pos.x, top_left_pos.y, 
		output_resolution.x, output_resolution.y, 
		vertical_cutoff.x, vertical_cutoff.y
	]).to_byte_array()
	byte_array.append_array(
		PackedFloat32Array([
			max_index_size, pixels_per_index, ant_per_index_size, queen_per_index_size, enemy_per_index_size, food_per_index_size, 0, 0
		]).to_byte_array()
	)
	return byte_array
