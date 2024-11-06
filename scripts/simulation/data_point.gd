# Class for storing data at a point
# READONLY
class_name DataPoint extends Object

# Number of data entries (ex. num_ants)
const NUM_DATA_ENTRIES = 4

# Seperate new function for writing out data manually
static func new_enum(init_num_ants: int, init_num_food: int, init_num_queens: int, init_num_enemies: int) -> DataPoint:
	return DataPoint.new(PackedInt64Array([init_num_ants, init_num_food, init_num_queens, init_num_enemies]))

static func copy(data_point: DataPoint) -> DataPoint:
	return DataPoint.new(data_point._data_entries)


var _data_entries: PackedInt64Array

func _init(init_data_entries: PackedInt64Array) -> void:
	assert(init_data_entries.size() == NUM_DATA_ENTRIES, \
		"Dimension mismatch. data_entries has size %s. Should be %s. " % [init_data_entries.size(), NUM_DATA_ENTRIES])
	
	_data_entries = init_data_entries

func get_data_entries() -> PackedInt64Array:
	return _data_entries
func get_num_ants() -> int:
	return _data_entries[0]
func get_num_food() -> int:
	return _data_entries[1]
func get_num_queens() -> int:
	return _data_entries[2]
func get_num_enemies() -> int:
	return _data_entries[3]
