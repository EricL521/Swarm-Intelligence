# Class for storing data at a point
class_name DataPoint extends Object

# Number of data entries (ex. num_ants)
const NUM_DATA_ENTRIES = 4

# Seperate new function for writing out data manually
static func new_enum(num_ants: int, num_food: int, num_queen: int, num_enemies: int) -> DataPoint:
	var temp_array: Array = [num_ants, num_food, num_queen, num_enemies]
	var data_entries = PackedInt64Array(temp_array)
	
	return DataPoint.new(data_entries)

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

func _init(data_entries: PackedInt64Array) -> void:
	self.data_entries = data_entries
