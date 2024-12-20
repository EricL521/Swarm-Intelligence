# A class with functions for updating world
class_name WorldUpdater extends Object

# How many frames to wait before sync
const GPU_SYNC_WAIT = 3

# signal emitted on GPU sync
signal gpu_sync

var world: World
# Used for timer
var _tree: SceneTree
# GPU Stuff
var _world_data_bytes: PackedByteArray
var _world_size_bytes: PackedByteArray
var _shader_spirv: RDShaderSPIRV
var rd: RenderingDevice

func _init(shader_file, init_world, init_tree) -> void:
	# Load GLSL shader
	_shader_spirv = shader_file.get_spirv()
	
	_tree = init_tree
	
	# Prepare our data
	world = init_world
	_world_data_bytes = world.data.to_byte_array()
	_world_size_bytes = PackedInt32Array([world.get_size_x(), world.get_size_y(), world.get_size_z(), DataPoint.NUM_DATA_ENTRIES]).to_byte_array()
	
	rd = RenderingServer.create_local_rendering_device()

# Emits a signal 
func update() -> void:
	# Create a local rendering device.
	var shader = rd.shader_create_from_spirv(_shader_spirv)
	
	# Create a compute pipeline
	var pipeline := rd.compute_pipeline_create(shader)
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	
	# Add buffer data
	var world_data_buffer_input := rd.storage_buffer_create(_world_data_bytes.size(), _world_data_bytes)
	add_buffer(compute_list, shader, world_data_buffer_input, 0)
	var world_data_buffer := rd.storage_buffer_create(_world_data_bytes.size(), _world_data_bytes)
	add_buffer(compute_list, shader, world_data_buffer, 1)
	var world_size_buffer := rd.storage_buffer_create(_world_size_bytes.size(), _world_size_bytes)
	add_buffer(compute_list, shader, world_size_buffer, 2)
	
	rd.compute_list_dispatch(compute_list, world.get_size_x(), world.get_size_y(), world.get_size_z())
	rd.compute_list_end()
	
	# Submit to GPU
	rd.submit()
	# Wait GPU_SYNC_WAIT frames
	for i in range(GPU_SYNC_WAIT):
		await _tree.process_frame
	rd.sync()
	
	# Read back the data from the buffer
	_world_data_bytes = rd.buffer_get_data(world_data_buffer)
	world.data = _world_data_bytes.to_int64_array()
	gpu_sync.emit()

func add_buffer(compute_list: int, shader: RID, buffer: RID, binding: int) -> void:
	# Create a uniform to assign the buffer to the rendering device
	var uniform := RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform.binding = binding # this needs to match the "binding" in our shader file
	uniform.add_id(buffer)
	var uniform_set := rd.uniform_set_create([uniform], shader, binding) # the last parameter (the 0) needs to match the "set" in our shader file
	
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, binding)
