extends Camera3D

@export var move_speed = 0.1
@export var rotate_speed = 0.25
@export var x_rotation = 0
@export var y_rotation = -40

@onready var rotating = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var local_transform = Vector3.ZERO
	if Input.is_action_pressed("camera_forwards"):
		local_transform += Vector3.FORWARD
	if Input.is_action_pressed("camera_backwards"):
		local_transform += Vector3.BACK
	if Input.is_action_pressed("camera_left"):
		local_transform += Vector3.LEFT
	if Input.is_action_pressed("camera_right"):
		local_transform += Vector3.RIGHT
	if Input.is_action_pressed("camera_down"):
		transform = transform.translated(Vector3.DOWN * move_speed)
	if Input.is_action_pressed("camera_up"):
		transform = transform.translated(Vector3.UP * move_speed)
	# Apply transform
	transform = transform.translated_local(local_transform.normalized() * move_speed)
	
	if Input.is_action_just_pressed("toggle_rotate"):
		rotating = not rotating
		if (rotating): Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else: Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# used for detecting mouse movement
func _input(event):
	if rotating and event is InputEventMouseMotion:
		x_rotation += -event.relative.x * rotate_speed
		y_rotation += -event.relative.y * rotate_speed
		# limit y_rotation
		y_rotation = clamp(y_rotation, -90, 90)
		
		# Update basis
		transform.basis = Basis() # reset rotation
		rotate_object_local(Vector3.UP, deg_to_rad(x_rotation)) # first rotate in Y
		rotate_object_local(Vector3.RIGHT, deg_to_rad(y_rotation)) # then rotate in X

