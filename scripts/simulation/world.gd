# Class for storing world data
class_name World extends Object

# In general we store a 4d array with information about each "chunk" of the world
var min_x: int
var max_x: int
var size_x: int:
	get: return max_x - min_x + 1
var min_y: int
var max_y: int
var size_y: int:
	get: return max_x - min_x + 1
var min_z: int
var max_z: int
var size_z: int:
	get: return max_x - min_x + 1
# Data is stored in this order:
# num_ants, num_food, num_queens, num_enemies
var data: PackedInt64Array
var size_data: PackedFloat32Array

# size variables are how many entries in that direction to store
# scaling functions are how big the corresponding int is
func _init(min_x: int, max_x: int, min_y: int, max_y: int, min_z: int, max_z: int, data: PackedInt64Array = PackedInt64Array([])) -> void:
	self.min_x = min_x
	self.max_x = max_x
	self.min_y = min_y
	self.max_y = max_y
	self.min_z = min_z
	self.max_z = max_z
	
	# Initialize data if it is empty
	if data.size() == 0:
		pass
	elif data.size() == size_x * size_y * size_z * DataPoint.NUM_DATA_ENTRIES:
		self.data = data
	else:
		assert("Data dimension mismatch. Given array has size %s, but should be %s. " \
			% [data.size(), size_x * size_y * size_z * DataPoint.NUM_DATA_ENTRIES])

# Sets data at a position
func set_data(x: int, y: int, z: int, data_point: DataPoint) -> void:
	for i in range(DataPoint.NUM_DATA_ENTRIES):
		data[get_index(x, y, z, i)] = data_point.data_entries[i]

# Gets data at a position
func get_data(x: int, y: int, z: int) -> DataPoint:
	var data_entries = PackedInt64Array([])
	for i in range(DataPoint.NUM_DATA_ENTRIES):
		data_entries.append(data[get_index(x, y, z, i)])
	return DataPoint.new(data_entries)

# Returns the index of a coordinate
func get_index(x: int, y: int, z: int, data_entry: int) -> int:
	if (x < min_x or x >= max_x):
		assert("x (%s) out of bounds. Should be between %s and %s, inclusive. " % [x, min_x, max_x])
	if (y < min_y or y >= max_y):
		assert("y (%s) out of bounds. Should be between %s and %s, inclusive. " % [y, min_y, max_y])
	if (z < min_z or z > max_z):
		assert("z (%s) out of bounds. Should be between %s and %s, inclusive. " % [z, min_z, max_z])
	if (data_entry < 0 or data_entry >= DataPoint.NUM_DATA_ENTRIES):
		assert("data_entry (%s) out of bounds. Should be between 0 and %s" % [data_entry, DataPoint.NUM_DATA_ENTRIES])
	return ((x - min_x) * size_y * size_z * DataPoint.NUM_DATA_ENTRIES) \
		+ ((y - min_y) * size_z * DataPoint.NUM_DATA_ENTRIES) \
		+ ((z - min_z) * DataPoint.NUM_DATA_ENTRIES) \
		+ (data_entry)
