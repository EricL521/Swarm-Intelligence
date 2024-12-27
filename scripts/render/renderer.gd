class_name Renderer extends ComputeShader

signal render(texture: ImageTexture)

var world: World
var _render_settings: RenderSettings
var _blend_texture: Texture2D

var _world_data_buffer: RID
var _world_size_buffer: RID
var _render_settings_buffer: RID
var _blend_texture_buffer: RID
var _output_texture_buffer: RID

func _init(shader_file: Resource, init_tree: SceneTree, init_world: World, render_settings: RenderSettings, blend_texture: Texture2D) -> void:
	super(shader_file, init_tree)
	world = init_world
	_render_settings = render_settings
	_blend_texture = blend_texture
	
	gpu_sync.connect(_on_gpu_sync)
	
	init_buffers(true)

# If initial is false, then only world_data_buffer is updated
func init_buffers(initial: bool) -> void:
	var world_data_bytes := world.data.to_byte_array()
	_world_data_buffer = rd.storage_buffer_create(world_data_bytes.size(), world_data_bytes)
	
	if initial:
		var world_size_bytes := PackedInt32Array([world.get_size_x(), world.get_size_y(), world.get_size_z(), DataPoint.NUM_DATA_ENTRIES]).to_byte_array()
		_world_size_buffer = rd.storage_buffer_create(world_size_bytes.size(), world_size_bytes)
		
		var render_settings_bytes := PackedInt32Array(_render_settings.to_array()).to_byte_array()
		_render_settings_buffer = rd.uniform_buffer_create(render_settings_bytes.size(), render_settings_bytes)
		
		var blend_texture_format := RDTextureFormat.new()
		blend_texture_format.width = int(_blend_texture.get_size().x)
		blend_texture_format.height = int(_blend_texture.get_size().y)
		blend_texture_format.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
		blend_texture_format.usage_bits = RenderingDevice.TEXTURE_USAGE_STORAGE_BIT \
			| RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT \
			| RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
		var blend_texture_image := _blend_texture.get_image()
		blend_texture_image.convert(Image.FORMAT_RGBAF)
		_blend_texture_buffer = rd.texture_create(blend_texture_format, RDTextureView.new(), [blend_texture_image.get_data()])
		
		var output_texture_format := RDTextureFormat.new()
		output_texture_format.width = _render_settings.output_resolution.x
		output_texture_format.height = _render_settings.output_resolution.y
		output_texture_format.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
		output_texture_format.usage_bits = RenderingDevice.TEXTURE_USAGE_STORAGE_BIT \
			| RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT \
			| RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
		_output_texture_buffer = rd.texture_create(output_texture_format, RDTextureView.new())

func render_screen():
	init_buffers(false)
	run_shader(
		Vector3i(_render_settings.output_resolution.x, _render_settings.output_resolution.y, 1), 0, 
		[RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER, 
			RenderingDevice.UNIFORM_TYPE_IMAGE, RenderingDevice.UNIFORM_TYPE_IMAGE], 
		[_world_data_buffer, _world_size_buffer, _render_settings_buffer, _blend_texture_buffer, _output_texture_buffer],
		[0, 1, 2, 3, 4]
	)

func _on_gpu_sync(_rd: RenderingDevice):
	var image_data = rd.texture_get_data(_output_texture_buffer, 0)
	var new_image := Image.create_from_data(_render_settings.output_resolution.x, _render_settings.output_resolution.y, false, Image.FORMAT_RGBAF, image_data)
	var new_image_texture := ImageTexture.create_from_image(new_image)
	
	render.emit(new_image_texture)
