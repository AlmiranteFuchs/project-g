extends CharacterBody3D

##### References #####
@onready var camera_3d = $p_head/Camera3D
@onready var character_body_3d = $"."
@onready var p_head = $p_head
@onready var collision_shape_3d = $CollisionShape3D
@onready var p_chest = $p_chest
@onready var p_legs = $p_legs

##### Constants #####
const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSE = 0.25
const WALL_RUN_RAY_LENGTH = 3.0
const WALL_RUN_ANGLE = 2

##### Global Variables #####
var camera_anglev = 0
var collisions = []

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

##### Functions #####
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) # Change this in the future

func _physics_process(delta):
	manage_movement(delta)
	#wall_ray_cast()
	climb_wall()
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
	var target_direction = (p_head.global_transform.basis.z).normalized()
	var angle_offset_degrees = WALL_RUN_ANGLE # Adjust this value to change the offset angle
	var angle_radians = deg_to_rad(angle_offset_degrees)
	var offset_direction = target_direction.rotated(Vector3.UP, angle_radians)
	var offset_direction2 = target_direction.rotated(Vector3.UP, -angle_radians)

	# Now use the offset_direction to cast the ray
	# The second one is for the other side
	var ray_start = p_head.global_position
	var ray_end = ray_start - offset_direction * WALL_RUN_RAY_LENGTH
	var ray_end2 = ray_start - offset_direction2 * WALL_RUN_RAY_LENGTH

	var ray_parameters = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	var ray_parameters2 = PhysicsRayQueryParameters3D.create(ray_start, ray_end2)

	var collision = space.intersect_ray(ray_parameters)
	var collision2 = space.intersect_ray(ray_parameters2)

	line(p_head.global_position, ray_start - offset_direction * WALL_RUN_RAY_LENGTH, Color.RED, 1)
	line(p_head.global_position, ray_start - offset_direction2 * WALL_RUN_RAY_LENGTH, Color.RED, 1)

	if ((collision&&collision2)&&collision.collider == collision2.collider):
		line(collision.position, collision2.position, Color.GREEN, 1)
		# Check if the player is colliding with the wall
		for i in get_slide_collision_count():
			var col = get_slide_collision(i)
			if (col.get_collider()) == collision.collider:
				# Move the player to the wall
				var wall_normal = collision.normal
				var wall_direction = wall_normal.cross(Vector3.UP)

				# If the first collision point is closer to the player than make the wall direction negative
				if (p_head.global_position - collision.position).length() < (p_head.global_position - collision2.position).length():
					wall_direction = -wall_direction

				velocity = wall_direction * SPEED * 0.5
				velocity.y = 0
				
				break

var started_climbing = false
func climb_wall():
	# If not on wall
	if not is_on_wall():
		return
	var space = get_world_3d().direct_space_state

	# TODO: Save collisions points in a array, reverse it, if collided with the wall, take the first point and compare the z of the next, while it is the same do nothing
	# If it changes, probably the point it's above the wall, where the player needs to climb, 
	# hint: collision.position
	# Bonus: set the player position on that point, it will look like shit but It will work for now, after we can look on interpolation or fancy x² funcs for smooooothing things ip 

	var starting_pos = p_head.global_position + Vector3(0, 2, 0)
	for i in 5:
		starting_pos = starting_pos - Vector3(0, 0.5, 0)
		var target_dir = (p_head.basis.z.normalized())
		var angle_radians = deg_to_rad(50)
		var offset_direction = target_dir.rotated(Vector3.LEFT, angle_radians)
		var ending_end = (starting_pos - (offset_direction * WALL_RUN_RAY_LENGTH))

		var ray_parameters = PhysicsRayQueryParameters3D.create(starting_pos, ending_end)
		var collision = space.intersect_ray(ray_parameters)

		line(starting_pos, ending_end, Color.RED, 1)

	return ;
	# # If not on wall
	# if not is_on_wall():
	# 	return
	# # Get the height of the collided object
	# var collision = get_slide_collision(0)
	# if (collision == null):
	# 	return
	
	# # Object
	# var obj = collision.get_collider()
	# var obj_y_pos = obj.global_transform.origin.y

	# # Collide point?
	# var colll = collision.get_position()

	# # Player
	# var player_y_pos = global_transform.origin.y
	# print("obj> ", obj_y_pos)
	# print("player> ", player_y_pos)
	# print("on> ", colll)

func turn_camera(event):
	# Rotate the camera.
	character_body_3d.rotate_y(( - event.relative.x * MOUSE_SENSE / 120))
	var changev = -event.relative.y * MOUSE_SENSE
	if camera_anglev + changev > - 50 and camera_anglev + changev < 50:
		camera_anglev += changev
		camera_3d.rotate_x(deg_to_rad(changev))

# Debbuging 
func line(pos1: Vector3, pos2: Vector3, color=Color.WHITE_SMOKE, persist_ms=0.02):
	var mesh_instance := MeshInstance3D.new()
	var immediate_mesh := ImmediateMesh.new()
	var material := ORMMaterial3D.new()

	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	immediate_mesh.surface_add_vertex(pos1)
	immediate_mesh.surface_add_vertex(pos2)
	immediate_mesh.surface_end()

	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color

	return await final_cleanup(mesh_instance, persist_ms)

func final_cleanup(mesh_instance: MeshInstance3D, persist_ms: float):
	get_tree().get_root().add_child(mesh_instance)
	if persist_ms == 1:
		await get_tree().physics_frame
		mesh_instance.queue_free()
	elif persist_ms > 0:
		await get_tree().create_timer(persist_ms).timeout
		mesh_instance.queue_free()
	else:
		return mesh_instance
