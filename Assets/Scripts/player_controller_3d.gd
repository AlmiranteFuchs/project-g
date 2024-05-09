extends CharacterBody3D
@onready var camera_3d = $p_head/Camera3D
@onready var p_head = $p_head
@onready var character_body_3d = $"."

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSE = 0.25
var camera_anglev = 0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	is_on_wall()

	# Handle jump.
	if Input.is_action_just_pressed("ui_character_movement_up") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("ui_character_movement_left", "ui_character_movement_right", "ui_character_movement_forward", "ui_character_movement_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func _input(event):
	if event is InputEventMouseMotion:
		character_body_3d.rotate_y((-event.relative.x * MOUSE_SENSE/100))
		var changev = -event.relative.y * MOUSE_SENSE
		character_body_3d.rotate_y((-event.relative.x * MOUSE_SENSE/100))
		
		if camera_anglev + changev > - 50 and camera_anglev + changev < 50:
			camera_anglev += changev
			camera_3d.rotate_x(deg_to_rad(changev))
		

