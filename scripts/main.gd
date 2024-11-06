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
var world_updater: WorldUpdater

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_timer.timeout.connect(_on_timer_timeout)
	
	# Prepare our data
	world = World.new(min_x, max_x, min_y, max_y, min_z, max_z, [])
	world_updater = WorldUpdater.new(shader_file, world, get_tree())
	
	world_updater.gpu_sync.connect(_on_gpu_sync)

func _on_timer_timeout() -> void:
	world_updater.update()

func _on_gpu_sync() -> void:
	print(world.data)
