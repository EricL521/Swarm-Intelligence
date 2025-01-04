# A class with functions for updating world
class_name WorldUpdater extends ComputeShader

signal world_update

# How many frames to wait before sync
const GPU_SYNC_WAIT = 3

var world: World
# GPU Stuff
var _world_data_bytes: PackedByteArray
var _world_data_buffer: RID
var _world_size_bytes: PackedByteArray

func _init(shader_file, init_world, init_tree) -> void:
	super(shader_file, init_tree)
	
	# Prepare our data
	world = init_world
	_world_data_bytes = world.data.to_byte_array()
	_world_size_bytes = PackedInt32Array([world.get_size_x(), world.get_size_y(), world.get_size_z(), DataPoint.NUM_DATA_ENTRIES]).to_byte_array()
	
	gpu_sync.connect(_on_gpu_sync)

# Emits a signal 
func update() -> void:
	# Add buffer data
	var world_data_buffer_input := rd.storage_buffer_create(_world_data_bytes.size(), _world_data_bytes)
	_world_data_buffer = rd.storage_buffer_create(_world_data_bytes.size(), _world_data_bytes)
	var world_size_buffer := rd.storage_buffer_create(_world_size_bytes.size(), _world_size_bytes)
	
	run_shader(Vector3i(world.get_size_x(), world.get_size_y(), world.get_size_z()), GPU_SYNC_WAIT, \
		[RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER], \
		[world_data_buffer_input, _world_data_buffer, world_size_buffer], [0, 1, 2])

func _on_gpu_sync(_rd: RenderingDevice) -> void:
	# Read back the data from the buffer
	_world_data_bytes = rd.buffer_get_data(_world_data_buffer)
	world.data = _world_data_bytes.to_int32_array()
	world_update.emit()
