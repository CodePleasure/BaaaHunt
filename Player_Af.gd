extends KinematicBody

const JUMP_SPEED = 14
const GRAVITY = -32
const CAMERA_ROTATION_SLOW = 0.0025
const CAMERA_ROTATION_FAST = 0.025
const CAMERA_SLERP_TRANSITION_DIFF = 0.025

var MAX_SPEED = 5
var ACCEL = 8
var DEACCEL = 8

var camera_rot
var player_basis
var player_rot
var player_vel
var model_scale
var animation_manager

var dir = Vector3()
export var vel = Vector3()

var is_looking = false
var is_sprinting = false

var is_rolling = false
var is_jumping = false
var is_crouching = false
var is_on_air = false
var is_aiming = false
var freeze_position = false
var is_animation_changeable = true

var input_movement_vector = Vector2()

func _ready():
	
	camera_rot = CAMERA_ROTATION_SLOW
	player_basis = $Armature.transform.orthonormalized().basis
	player_rot = $Armature.rotation.y
	model_scale = $Armature.scale
	
	animation_manager = $Animation_Player
	
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _physics_process(delta):
	process_input(delta)
	process_model_animation(delta)
	process_model_rotation(delta)
	process_model_direction(delta)
	process_quick_slerp_camera(delta)
	process_model_movement(delta)
	process_camera_movement(delta)

func process_input(delta):
	input_movement_vector = Vector2()
	
	if Input.is_action_pressed("joypad_axis_left_up"):
		if Input.is_joy_button_pressed(0, JOY_AXIS_1): 
			input_movement_vector.y -= Input.get_action_strength("joypad_axis_left_up")
		elif Input.is_key_pressed(KEY_W):
			input_movement_vector.y -= 1
	if Input.is_action_pressed("joypad_axis_left_down"):
		if Input.is_joy_button_pressed(0, JOY_AXIS_1): 
			input_movement_vector.y += Input.get_action_strength("joypad_axis_left_down") 
		elif Input.is_key_pressed(KEY_S):
			input_movement_vector.y += 1
	if Input.is_action_pressed("joypad_axis_left_left"):
		if Input.is_joy_button_pressed(0, JOY_AXIS_0): 
			input_movement_vector.x += Input.get_action_strength("joypad_axis_left_left")
		elif Input.is_key_pressed(KEY_A):
			input_movement_vector.x += 1
	if Input.is_action_pressed("joypad_axis_left_right"):
		if Input.is_joy_button_pressed(0, JOY_AXIS_0): 
			input_movement_vector.x -= Input.get_action_strength("joypad_axis_left_right")
		elif Input.is_key_pressed(KEY_D):
			input_movement_vector.x -= 1
		
	input_movement_vector = input_movement_vector.normalized()

func process_model_animation(delta):
	if is_aiming == true:
		if is_animation_changeable == true:
			if Input.is_action_just_released("action_draw_arrow"):
				animation_manager.set_animation("Standing Idle 01")
			elif not Input.is_action_pressed("action_draw_arrow"):
				animation_manager.set_animation("Standing Idle 01")
	elif is_crouching == false:
		if Input.is_action_just_pressed("movement_crouch"):
			animation_manager.set_animation("Standing To Crouch")
		elif Input.is_action_just_pressed("action_draw_arrow"):
			animation_manager.set_animation("Standing Draw Arrow")
		elif is_animation_changeable == true:
			if is_to_move() == true:
				animation_manager.set_animation("Standing Run Forward")
			else:
				animation_manager.set_animation("Standing Idle 01")
	elif is_crouching == true:
		if Input.is_action_just_released("movement_crouch"):
			animation_manager.set_animation("Crouch To Standing")
		elif is_animation_changeable == true:
			if is_to_move() == true:
				animation_manager.set_animation("Crouch Walk Forward")
			else:
				animation_manager.set_animation("Crouch Idle 01")

func process_model_rotation(delta):
	if Vector2(0,0) == input_movement_vector:
		return
	
	if freeze_position == true:
		return
		
	if is_aiming == true:
		return

	var rotation = xy2rad(input_movement_vector) + $Camera_Rotate.rotation.y
	$Armature.rotation = Vector3(PI/2, rotation, 0)
	$Armature.orthonormalize()
	$Armature.scale = model_scale

func process_model_direction(delta):
	dir = Vector3()
	
	if freeze_position == true:
		return
	
	if is_aiming == true:
		return

	dir += -get_transform().basis.z * input_movement_vector.y
	dir += get_transform().basis.x * input_movement_vector.x

func process_quick_slerp_camera(delta):
	if Input.is_action_just_pressed("camera_slerp_fast") == false:
		return
	
	if freeze_position == true:
		return

	camera_rot = CAMERA_ROTATION_FAST
	player_basis = $Armature.transform.orthonormalized().basis
	player_rot = $Armature.rotation.y

func process_camera_movement(delta):
	var player_dir = dir
	
	$Camera_Rotate/Camera.current = true
	
	var cam_basis = $Camera_Rotate.transform.orthonormalized().basis
	if camera_rot == CAMERA_ROTATION_SLOW:
		if abs(player_dir.z) < 1:
			player_basis = $Armature.transform.orthonormalized().basis
			player_rot = $Armature.rotation.y

	var new_rotation = Quat(cam_basis).slerp(player_basis, camera_rot)

	$Camera_Rotate.transform = Transform(new_rotation, Vector3(0, 1, 0))
	$Camera_Rotate.rotation.x = 0
	$Camera_Rotate.rotation.z = 0

	if abs($Camera_Rotate.rotation.y - player_rot) < CAMERA_SLERP_TRANSITION_DIFF:
		camera_rot = CAMERA_ROTATION_SLOW

func process_model_movement(delta):
	if freeze_position == true:
		return

	var player_dir = dir
	
	player_dir = player_dir.rotated(Vector3(0, 1, 0), $Camera_Rotate.rotation.y)
	player_dir.y = 0
	player_dir = player_dir.normalized()
	
	vel.y += delta * GRAVITY
	
	var hvel = vel
	hvel.y = 0
	
	var target = player_dir
	target *= MAX_SPEED

	var accel
	if player_dir.dot(hvel) > 0:
		accel = ACCEL
	else:
		accel = DEACCEL
	
	hvel = hvel.linear_interpolate(target, accel * delta)
	vel.x = hvel.x
	vel.z = hvel.z

	vel = move_and_slide(vel, Vector3(0, 1, 0), true )

func xy2rad(vec):
	if vec.x >= 0:
		if vec.y >= 0:
			return (PI / 2) + asin(vec.y)
		else:
			return asin(vec.x)
	else:
		if vec.y < 0:
			return (PI * 3/2) + asin(-vec.y)
		else:
			return (PI) + asin(-vec.x)

func get_linear_interpolate_x_only(x_pos, x_target, accel, delta):
	var pos = Vector2(x_pos, 0)
	var target = Vector2(x_target, 0)
	
	return pos.linear_interpolate(target, accel * delta).x

func set_crouching(value):
	is_crouching = value

	if is_crouching == true:
		MAX_SPEED = 2
		ACCEL = 4
		DEACCEL = 4
	else:
		MAX_SPEED = 5
		ACCEL = 8
		DEACCEL = 8

func hold_changes(value):
	freeze_position = value
	is_animation_changeable = !value
	vel = Vector3()

func set_aiming(value):
	is_aiming = value

func is_to_move():
	return Vector2(0, 0) != input_movement_vector