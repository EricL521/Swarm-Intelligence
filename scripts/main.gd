extends Node2D

signal initialize

@export var sim_shader_file: Resource
@export var update_timer: Timer
@export var min_x: int = -10
@export var max_x: int = 10
@export var min_y: int = -5
@export var max_y: int = 5
@export var min_z: int = -10
@export var max_z: int = 10

var world: World
var world_updater: WorldUpdater
var update_start_time: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_timer.timeout.connect(_on_timer_timeout)
	
	# Prepare our data
	world = World.new(min_x, max_x, min_y, max_y, min_z, max_z)
	world.set_data(0, 0, 0, DataPoint.new_enum(0, 1000, 1, 0))
	world_updater = WorldUpdater.new(sim_shader_file, world, get_tree())
	
	world_updater.world_update.connect(_on_world_update)
	
	initialize.emit()

func _on_timer_timeout() -> void:
	update_start_time = Time.get_ticks_msec()
	print("starting update")
	world_updater.update()

@onready var temp = 0

func _on_world_update() -> void:
	#print(world.data)
	temp += 1
	if temp > 10:
		temp = 0
		var total_ants = 0
		var total_queens = 0
		var total_enemies = 0
		var total_food = 0
		for x in range(min_x, max_x + 1):
			for y in range(min_y, max_y + 1):
				for z in range(min_z, max_z + 1):
					total_ants += world.get_data(x, y, z).get_num_ants()
					total_queens += world.get_data(x, y, z).get_num_queens()
					total_food += world.get_data(x, y, z).get_num_food()
					total_enemies += world.get_data(x, y, z).get_num_enemies()
		print(total_ants, " ", total_queens, " ", total_food, " ", total_enemies, " ", Time.get_ticks_msec() - update_start_time)
	pass
