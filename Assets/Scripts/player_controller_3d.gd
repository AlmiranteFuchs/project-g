extends CharacterBody3D

##### References #####
@onready var camera_3d = $p_head/Camera3D
@onready var character_body_3d = $"."

##### Constants #####
const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSE = 0.25
const WALL_RUN_RAY_LENGTH = 3.0

##### Global Variables #####
var camera_anglev = 0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

##### Functions #####
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) # Change this in the future

func _physics_process(delta):
	manage_movement(delta)
	wall_ray_cast()
	move_and_slide()

func _input(event):
	# Handle the mouse movement.
	if event is InputEventMouseMotion:
		turn_camera(event)
	
	if event is InputEventKey:
		if event.is_pressed():
			if event.keycode == KEY_ESCAPE:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
###### Custom Functions #####
func manage_movement(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		# Handle jump.
		if Input.is_action_just_pressed("ui_character_movement_up") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		# Get the input direction and handle the movement/deceleration.
		var input_dir = Input.get_vector("ui_character_movement_left", "ui_character_movement_right", "ui_character_movement_forward", "ui_character_movement_back")
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)

func wall_ray_cast():
	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(camera_3d.global_position, camera_3d.global_position - camera_3d.global_transform.basis.z * WALL_RUN_RAY_LENGTH)
	var collision = space.intersect_ray(query)
	if(collision):
		print(collision.collider)

	


func turn_camera(event):
	# Rotate the camera.
	character_body_3d.rotate_y(( - event.relative.x * MOUSE_SENSE / 120))
	var changev = -event.relative.y * MOUSE_SENSE
	if camera_anglev + changev > - 50 and camera_anglev + changev < 50:
		camera_anglev += changev
		camera_3d.rotate_x(deg_to_rad(changev))
