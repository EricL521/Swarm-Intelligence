extends Sprite2D

@export var render_shader_file: Resource
@export var blend_texture: Texture
@export var world_node: Node

var renderer: Renderer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	world_node.initialize.connect(_on_initialize)

func _on_initialize() -> void:
	renderer = Renderer.new(render_shader_file, get_tree(), world_node.world, RenderSettings.new(
		blend_texture.get_size(), Vector2i(0, 0), Vector2i(1000, 1000), Vector2i(0, 0), 1000/11, 20, 20, 20, 20
	), blend_texture)
	
	renderer.render.connect(_on_render)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	renderer.render_screen()

func _on_render(new_texture: ImageTexture) -> void:
	texture = new_texture
