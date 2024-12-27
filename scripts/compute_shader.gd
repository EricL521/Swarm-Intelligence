# Class for managing compute shader
class_name ComputeShader extends Object

# signal emitted on GPU sync
signal gpu_sync(rd: RenderingDevice)

# Tree used for frame waiting
var _tree: SceneTree
var _shader_spirv: RDShaderSPIRV
var rd: RenderingDevice

func _init(shader_file: Resource, init_tree: SceneTree) -> void:
	_tree = init_tree
	# Load GLSL shader & Create rendering server
	_shader_spirv = shader_file.get_spirv()
	rd = RenderingServer.create_local_rendering_device()

func run_shader(group_size: Vector3i, gpu_sync_wait_frames: int, \
uniform_type_array: Array[RenderingDevice.UniformType], rid_array: Array[RID], binding_array: Array[int]) -> void:
	# Create a local rendering device.
	var shader = rd.shader_create_from_spirv(_shader_spirv)
	
	# Create a compute pipeline
	var pipeline := rd.compute_pipeline_create(shader)
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	
	# Add buffer data
	assert(uniform_type_array.size() == rid_array.size() && rid_array.size() == binding_array.size(), "All array sizes must be the same")
	for i in range(uniform_type_array.size()):
		add_buffer(compute_list, shader, uniform_type_array[i], rid_array[i], binding_array[i])
	
	rd.compute_list_dispatch(compute_list, group_size.x, group_size.y, group_size.z)
	rd.compute_list_end()
	
	# Submit to GPU
	rd.submit()
	# Wait GPU_SYNC_WAIT frames
	for i in range(gpu_sync_wait_frames):
		await _tree.process_frame
	rd.sync()
	
	# Read back the data from the buffer
	gpu_sync.emit(rd)

func add_buffer(compute_list: int, shader: RID, uniform_type: RenderingDevice.UniformType, rid: RID, binding: int) -> void:
	# Create a uniform to assign the buffer to the rendering device
	var uniform := RDUniform.new()
	uniform.uniform_type = uniform_type
	uniform.binding = binding # this needs to match the "binding" in our shader file
	uniform.add_id(rid)
	var uniform_set := rd.uniform_set_create([uniform], shader, binding) # the last parameter (the 0) needs to match the "set" in our shader file
	
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, binding)
