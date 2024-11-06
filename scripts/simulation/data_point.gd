# Class for storing data at a point
class_name DataPoint extends Object

# Number of data entries (ex. num_ants)
const NUM_DATA_ENTRIES = 4

# Seperate new function for writing out data manually
static func new_enum(init_num_ants: int, init_num_food: int, init_num_queens: int, init_num_enemies: int) -> DataPoint:
	var temp_array: Array = [init_num_ants, init_num_food, init_num_queens, init_num_enemies]
	var init_data_entries = PackedInt64Array(temp_array)
	
	return DataPoint.new(init_data_entries)

var data_entries: PackedInt64Array

var num_ants: int:
	set(value): data_entries[0] = value
	get: return data_entries[0]
var num_food: int:
	set(value): data_entries[1] = value
	get: return data_entries[1]
var num_queens: int:
	set(value): data_entries[2] = value
	get: return data_entries[2]
var num_enemies: int:
	set(value): data_entries[3] = value
	get: return data_entries[3]

func _init(init_data_entries: PackedInt64Array) -> void:
	assert(init_data_entries.size() == NUM_DATA_ENTRIES, \
		"Dimension mismatch. data_entries has size %s. Should be %s. " % [init_data_entries.size(), NUM_DATA_ENTRIES])
	
	data_entries = init_data_entries
