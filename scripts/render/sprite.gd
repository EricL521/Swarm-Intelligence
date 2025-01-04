extends Sprite2D

@export var render_shader_file: Resource
@export var blend_texture: Texture
@export var world_node: Node

var renderer: Renderer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	world_node.initialize.connect(_on_initialize)

func _on_initialize() -> void:
	var render_settings := RenderSettings.new()
	render_settings.blend_texture_size = blend_texture.get_size()
	render_settings.top_left_pos = Vector2i(0, 0)
	render_settings.output_resolution = Vector2i(1000, 1000)
	render_settings.vertical_cutoff = Vector2i(1, 2)
	render_settings.max_index_size = 3
	render_settings.pixels_per_index = 1000.0/11
	render_settings.ant_per_index_size = 10
	render_settings.queen_per_index_size = 10
	render_settings.enemy_per_index_size = 10
	render_settings.food_per_index_size = 1000
	renderer = Renderer.new(render_shader_file, get_tree(), world_node.world, render_settings, blend_texture)
	
	renderer.render.connect(_on_render)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	renderer.render_screen()

func _on_render(new_texture: ImageTexture) -> void:
	texture = new_texture
