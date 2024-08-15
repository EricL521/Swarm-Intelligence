extends Node3D

@export var world_seed = 0
@export var mesh_shape = MESH_SHAPE.DIAGONAL
@export var chunk_size = 8 # chunk size in meters
@export var pixels_per_meter = 0.5 # might cause problems if chunk_size * pixels_per_meter isn't a whole number
@export var noise_scalar = 15 # noise values are multiplied by this amount

# stuff about the mesh shape for each pixel
# ex. box, 4 triangles, 2 triangles
# Options are {cross, diagonal, positive_diagonal}
# Format of each is [[shape], [shape], ...]
const mesh_shapes = [
	# Box with a cross in it
	[
		[Vector2(0, 0), Vector2(0, 1), Vector2(0.5, 0.5)],
		[Vector2(0, 1), Vector2(1, 1), Vector2(0.5, 0.5)],
		[Vector2(1, 1), Vector2(1, 0), Vector2(0.5, 0.5)],
		[Vector2(1, 0), Vector2(0, 0), Vector2(0.5, 0.5)]
	],
	# Box with a diagonal
	[
		[Vector2(0, 0), Vector2(0, 1), Vector2(1, 0)],
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0)]
	],
	# Box with a diagonal that has a positive slope
	[
		[Vector2(0, 0), Vector2(0, 1), Vector2(1, 1)],
		[Vector2(0, 0), Vector2(1, 1), Vector2(1, 0)]
	]
]
enum MESH_SHAPE {CROSS, DIAGONAL, POSITIVE_DIAGONAL}

var noise_generator; # Initialized in ready

# Called when the node enters the scene tree for the first time.
func _ready():
	noise_generator = FastNoiseLite.new()
	noise_generator.set_seed(world_seed)
	generate_chunks(-1, 1, -1, 1, true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_just_pressed("generate_world"):
		# Clear previously generate dchunks
		get_tree().call_group("chunks", "queue_free")
		
		world_seed = randf() * 100000
		noise_generator.set_seed(world_seed)
		
		generate_chunks(-5, 5, -5, 5, true)

func generate_chunks(x_min, x_max, y_min, y_max, reverse_winding_order):
	for x in range(x_min, x_max + 1):
		for y in range(y_min, y_max + 1):
			generate_chunk(x, y, reverse_winding_order)
# generates a chunk at inputed position
# note: 0, 0 is at the center of the chunk
# reverse_winding_order effectively changes the side that the mesh is visible on
func generate_chunk(x, y, reverse_winding_order):
	var array_mesh = generate_chunk_array_mesh(x, y, reverse_winding_order)
	
	var m = MeshInstance3D.new()
	m.mesh = array_mesh
	m.add_to_group("chunks")
	add_child(m)
# generates an arraymesh for a chunk
func generate_chunk_array_mesh(chunk_x, chunk_y, reverse_winding_order):
	# Initialize the ArrayMesh
	var array_mesh = ArrayMesh.new()
	
	for i in range(-1.0/2 * chunk_size * pixels_per_meter, 1.0/2 * chunk_size * pixels_per_meter):
		for j in range(-1.0/2 * chunk_size * pixels_per_meter, 1.0/2 * chunk_size * pixels_per_meter):
			for mesh in mesh_shapes[mesh_shape]:
				var vertices = PackedVector3Array()
				var normals = PackedVector3Array()
				# NOTE: Y is the up direction
				for k in range(mesh.size()):
					var vertex = mesh[mesh.size() - k - 1 if reverse_winding_order else k]
					var x_pos = (float(chunk_x) * chunk_size) + (float(i + vertex.x) / pixels_per_meter)
					var y_pos = (float(chunk_y) * chunk_size) + (float(j + vertex.y) / pixels_per_meter)
					vertices.push_back(Vector3(x_pos, get_height(x_pos, y_pos), y_pos))
				# Calculate normal of face
				var normal = (vertices[2] - vertices[0]).cross(vertices[1] - vertices[0])
				for k in range(mesh.size()): normals.push_back(normal)
				
				# Add surface to mesh
				var arrays = []
				arrays.resize(Mesh.ARRAY_MAX)
				arrays[Mesh.ARRAY_VERTEX] = vertices
				arrays[Mesh.ARRAY_NORMAL] = normals
				array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return array_mesh

# returns the height at x, y
# uses seed variable
# if you pass in noise, it won't make a new FastNoiseLite object every time
func get_height(x, y):
	return(noise_scalar * noise_generator.get_noise_2d(x, y))