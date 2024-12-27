class_name RenderSettings extends Object

var blend_texture_size: Vector2i
var top_left_pos: Vector2i
var output_resolution: Vector2i
# <bottom cutoff index, vertical cutoff index>, inclusive
var vertical_cutoff: Vector2i
# used to determine size of circles
var pixels_per_index: int 
var ant_per_index_size: int
var queen_per_index_size: int
var enemy_per_index_size: int
var food_per_index_size: int

func _init(init_blend_texture_size: Vector2i, init_top_left_pos: Vector2i, init_output_resolution: Vector2i, init_vertical_cutoff: Vector2i, \
init_pixels_per_index: int, init_ant_per_index_size: int, init_queen_per_index_size: int, init_enemy_per_index_size: int, init_food_per_index_size: int):
	blend_texture_size = init_blend_texture_size
	top_left_pos = init_top_left_pos
	output_resolution = init_output_resolution
	vertical_cutoff = init_vertical_cutoff
	pixels_per_index = init_pixels_per_index
	ant_per_index_size = init_ant_per_index_size
	queen_per_index_size = init_queen_per_index_size
	enemy_per_index_size = init_enemy_per_index_size
	food_per_index_size = init_food_per_index_size

func to_array() -> Array[int]:
	return [blend_texture_size.x, blend_texture_size.y, top_left_pos.x, top_left_pos.y, output_resolution.x, output_resolution.y, vertical_cutoff.x, vertical_cutoff.y, 
		pixels_per_index, ant_per_index_size, queen_per_index_size, enemy_per_index_size, food_per_index_size, 0, 0, 0]
