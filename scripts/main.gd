extends Node3D

@export var shader_file: Resource
@export var update_timer: Timer
@export var min_x: int = -10
@export var max_x: int = 10
@export var min_y: int = -10
@export var max_y: int = 10
@export var min_z: int = -10
@export var max_z: int = 10

var world: World

var input_bytes: PackedByteArray
var shader_spirv: RDShaderSPIRV

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_timer.timeout.connect(_on_timer_timeout)
	
	# Load GLSL shader
	shader_spirv = shader_file.get_spirv()
	
	# Prepare our data
	world = World.new(min_x, max_x, min_y, max_y, min_z, max_z)
	input_bytes = world.data.to_byte_array()


func _on_timer_timeout() -> void:
	update()

func update() -> void:
	# Create a local rendering device.
	var rd := RenderingServer.create_local_rendering_device()

	# Create a storage buffer
	var buffer := rd.storage_buffer_create(input_bytes.size(), input_bytes)
	
	var shader = rd.shader_create_from_spirv(shader_spirv)
	
	# Create a uniform to assign the buffer to the rendering device
	var uniform := RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform.binding = 0 # this needs to match the "binding" in our shader file
	uniform.add_id(buffer)
	var uniform_set := rd.uniform_set_create([uniform], shader, 0) # the last parameter (the 0) needs to match the "set" in our shader file
	
	# Create a compute pipeline
	var pipeline := rd.compute_pipeline_create(shader)
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_dispatch(compute_list, 100, 1, 1)
	rd.compute_list_end()
	
	# Submit to GPU and wait for sync
	rd.submit()
	rd.sync()
	
	# Read back the data from the buffer
	var output_bytes := rd.buffer_get_data(buffer)
	input_bytes = output_bytes
	world.data = output_bytes.to_int64_array()
	print("Output: ", world.data)
