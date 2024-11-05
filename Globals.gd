extends Node

# Store some global variables
var world_seed
var noise_generator
var noise_scalar

# Make some global functions

# returns the height at x, y
# uses seed variable
# if you pass in noise, it won't make a new FastNoiseLite object every time
func get_height(x, y):
	return(noise_scalar * noise_generator.get_noise_2d(x, y))
