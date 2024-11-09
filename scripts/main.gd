extends Node3D

@export var shader_file: Resource
@export var update_timer: Timer
@export var min_x: int = -10
@export var max_x: int = 10
@export var min_y: int = -5
@export var max_y: int = 5
@export var min_z: int = -10
@export var max_z: int = 10

var world: World
var world_updater: WorldUpdater

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_timer.timeout.connect(_on_timer_timeout)
	
	# Prepare our data
	world = World.new(min_x, max_x, min_y, max_y, min_z, max_z)
	world.set_data(0, 0, 0, DataPoint.new_enum(0, 100, 1, 0))
	world_updater = WorldUpdater.new(shader_file, world, get_tree())
	
	world_updater.gpu_sync.connect(_on_gpu_sync)

func _on_timer_timeout() -> void:
	world_updater.update()

func _on_gpu_sync() -> void:
	#print(world.data)
	var total_ants = 0
	var total_enemies = 0
	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			for z in range(min_z, max_z + 1):
				total_ants += world.get_data(x, y, z).get_num_ants()
				total_enemies += world.get_data(x, y, z).get_num_enemies()
	print(total_ants, " ", total_enemies)
