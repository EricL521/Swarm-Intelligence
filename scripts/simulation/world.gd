# Class for storing world data
class_name World extends Object

# In general we store a 4d array with information about each "chunk" of the world
# y is UP
var min_x: int
var max_x: int
func get_size_x() -> int:
	return max_x - min_x + 1
var min_y: int
var max_y: int
func get_size_y() -> int:
	return max_y - min_y + 1
var min_z: int
var max_z: int
func get_size_z() -> int:
	return max_z - min_z + 1
# Data is stored in this order:
# num_ants, num_food, num_queens, num_enemies
var data: PackedInt64Array
func get_data_size() -> int:
	return get_size_x() * get_size_y() * get_size_z() * DataPoint.NUM_DATA_ENTRIES

# size variables are how many entries in that direction to store
# scaling functions are how big the corresponding int is
func _init(init_min_x: int, init_max_x: int, init_min_y: int, init_max_y: int, init_min_z: int, init_max_z: int, init_data: PackedInt64Array = PackedInt64Array([])) -> void:
	min_x = init_min_x
	max_x = init_max_x
	min_y = init_min_y
	max_y = init_max_y
	min_z = init_min_z
	max_z = init_max_z
	
	# Initialize data if it is empty
	if init_data.size() == 0:
		data = PackedInt64Array([])
		data.resize(get_data_size())
		for x in range(min_x, max_x + 1):
			for y in range(min_y, max_y + 1):
				for z in range(min_z, max_z + 1):
					var temp_array = []
					temp_array.resize(DataPoint.NUM_DATA_ENTRIES)
					temp_array.fill(0)
					set_data(x, y, z, DataPoint.new(PackedInt64Array(temp_array)))
	else:
		assert(init_data.size() == get_data_size(), \
			"Dimension mismatch. data has size %s. Should be %s. " \
			% [init_data.size(), get_data_size()])
		
		data = init_data

# Sets data at a position
func set_data(x: int, y: int, z: int, data_point: DataPoint) -> void:
	for i in range(DataPoint.NUM_DATA_ENTRIES):
		data[get_index(x, y, z, i)] = data_point.get_data_entries()[i]

# Gets data at a position
func get_data(x: int, y: int, z: int) -> DataPoint:
	var data_entries = PackedInt64Array([])
	for i in range(DataPoint.NUM_DATA_ENTRIES):
		data_entries.append(data[get_index(x, y, z, i)])
	return DataPoint.new(data_entries)

# Returns the index of a coordinate
func get_index(x: int, y: int, z: int, data_entry: int) -> int:
	assert(x >= min_x and x <= max_x, \
		"x (%s) out of bounds. Should be between %s and %s, inclusive. " % [x, min_x, max_x])
	assert(y >= min_y and y <= max_y, \
		"y (%s) out of bounds. Should be between %s and %s, inclusive. " % [y, min_y, max_y])
	assert(z >= min_z and z <= max_z, \
		"z (%s) out of bounds. Should be between %s and %s, inclusive. " % [z, min_z, max_z])
	assert(data_entry >= 0 and data_entry < DataPoint.NUM_DATA_ENTRIES, 
		"data_entry (%s) out of bounds. Should be between 0 and %s, inclusive" % [data_entry, DataPoint.NUM_DATA_ENTRIES - 1])
	
	return ((x - min_x) * get_size_y() * get_size_z() * DataPoint.NUM_DATA_ENTRIES) \
		+ ((y - min_y) * get_size_z() * DataPoint.NUM_DATA_ENTRIES) \
		+ ((z - min_z) * DataPoint.NUM_DATA_ENTRIES) \
		+ (data_entry)
