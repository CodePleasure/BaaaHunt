extends KinematicBody

const JUMP_SPEED = 10
const GRAVITY = -32

const CAMERA_ROTATION_SLOW = 0.0025
const CAMERA_ROTATION_FAST = 0.025
const CAMERA_SLERP_TRANSITION_DIFF = 0.025
const PLAYER_ROTATION_ADJUSTMENT = -11*PI/32
var MAX_SPEED = 6
var ACCEL = 12
var DEACCEL = 12

var is_animation_changeable = true
var is_jumping = false
var freeze_position = false
var freeze_attack = false

var camera_rot
var player_basis
var player_rot
var model_scale

var input_movement_vector = Vector2()
var dir = Vector3()
var vel = Vector3()

var animation_manager_upper
var animation_manager_lower

var skeleton
var bone_upper_spine
var bone_upper_spine_id
var track_ids_upper_spine = {
	"Idle": -1,
	"Walking": -1,
	"Running": -1,
	"Jumping": -1,
	"Attack_01": -1,
	"Attack_02": -1,
}

# Temporary, this must be a arrow scene instead of just a string.
var arrows = ["Arrow_Regular", "Arrow_SpyCam"]
var arrow_idx = 0

func _ready():
	camera_rot = CAMERA_ROTATION_SLOW
	player_basis = $Armature.transform.orthonormalized().basis
	player_rot = $Armature.rotation.y
	model_scale = $Armature.scale
	
	skeleton = $Armature/Skeleton
	bone_upper_spine_id = skeleton.find_bone("Bip001 Head")
	bone_upper_spine = skeleton.get_bone_pose(bone_upper_spine_id)
	
	animation_manager_upper = $Armature/Skeleton/AnimationPlayer_Upper
	animation_manager_lower = $Armature/Skeleton/AnimationPlayer_Lower
	
	track_ids_upper_spine["Idle"] = animation_manager_upper.get_animation("Idle").find_track(".:Bip001 Spine1")
	track_ids_upper_spine["Walking"] = animation_manager_upper.get_animation("Walking").find_track(".:Bip001 Spine1")
	track_ids_upper_spine["Running"] = animation_manager_upper.get_animation("Running").find_track(".:Bip001 Spine1")
	track_ids_upper_spine["Jumping"] = animation_manager_upper.get_animation("Jumping").find_track(".:Bip001 Spine1")
	track_ids_upper_spine["Attack_01"] = animation_manager_upper.get_animation("Attack_01").find_track(".:Bip001 Spine1")
	track_ids_upper_spine["Attack_02"] = animation_manager_upper.get_animation("Attack_02").find_track(".:Bip001 Spine1")
	
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN) 
	
func _physics_process(delta):
	
	process_input(delta)
	process_model_animation(delta)
	process_model_rotation(delta)
	process_model_direction(delta)
	#process_animation_rotation(delta)
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
	
	if Input.is_action_just_pressed("switch_arrow"):
		arrow_idx = (arrow_idx + 1) % 2
	
func process_model_animation(delta):
	if Input.is_action_just_pressed("movement_jump"):
		play_animation("Jumping")
	if Input.is_action_just_pressed("action_attack"):
		if arrows[arrow_idx] == "Arrow_Regular":
			play_animation("Attack_01")
		else:
			play_animation("Attack_02")
	if is_to_move() == true:
		if Input.is_action_pressed("movement_walk"):
			play_animation("Walking")
		else:
			play_animation("Running")
	else:
		play_animation("Idle")

func play_animation(animation_name):
	animation_manager_lower.set_animation(animation_name)
	animation_manager_upper.set_animation(animation_name)

func process_model_rotation(delta):
	if Vector2(0,0) == input_movement_vector:
		return
	
	if freeze_position == true:
		return

	var rotation = xy2rad(input_movement_vector) + $Camera_Rotate.rotation.y
	$Armature.rotation = Vector3(0, rotation + PLAYER_ROTATION_ADJUSTMENT, 0)
	$Armature.orthonormalize()
	$Armature.scale = model_scale

func process_model_direction(delta):
	dir = Vector3()
	
	if freeze_position == true:
		return

	dir += -get_transform().basis.z * input_movement_vector.y
	dir += get_transform().basis.x * input_movement_vector.x

func process_animation_rotation(delta):
	var idx = track_ids_upper_spine[animation_manager_upper.current_animation]
	var loc = animation_manager_upper.get_current_animation_position() + 0.01
	
	var animation = animation_manager_upper.get_animation(animation_manager_upper.current_animation)
	var key_idx = animation.track_find_key(idx, loc)
	var t = animation.track_get_key_value(idx, key_idx)
	var qt = t["rotation"]
	qt.set_axis_angle(Vector3(1, 0, 0), PI/4)
	t["rotation"] = qt
	animation.track_set_key_value(idx, key_idx, t)

func process_camera_movement(delta):
	var player_dir = dir
	
	$Camera_Rotate/Camera.current = true
	
	var cam_basis = $Camera_Rotate.transform.orthonormalized().basis
	if camera_rot == CAMERA_ROTATION_SLOW:
		if abs(player_dir.z) < 1:
			player_basis = $Armature.transform.orthonormalized().basis
			player_basis = player_basis.rotated( Vector3(0, 1, 0), -PLAYER_ROTATION_ADJUSTMENT)
			player_rot = $Armature.rotation.y

	var new_rotation = Quat(cam_basis).slerp(player_basis, camera_rot)

	$Camera_Rotate.transform = Transform(new_rotation, Vector3(0, 1, 0))
	$Camera_Rotate.rotation.x = 0
	$Camera_Rotate.rotation.z = 0

	if abs($Camera_Rotate.rotation.y - player_rot) < CAMERA_SLERP_TRANSITION_DIFF:
		camera_rot = CAMERA_ROTATION_SLOW

func process_quick_slerp_camera(delta):
	if Input.is_action_just_pressed("camera_slerp_fast") == false:
		return
	
	if freeze_position == true:
		return

	camera_rot = CAMERA_ROTATION_FAST
	player_basis = $Armature.transform.orthonormalized().basis
	player_basis = player_basis.rotated( Vector3(0, 1, 0), -PLAYER_ROTATION_ADJUSTMENT)
	player_rot = $Armature.rotation.y
	
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

func is_to_move():
	return Vector2(0, 0) != input_movement_vector
	
func set_animation_changeable(value):
	is_animation_changeable = value

func freeze_position(value):
	freeze_position = value
	
func launch_jumping(value):
	if value == true:
		vel.y = JUMP_SPEED
	else:
		vel.y = 0

func set_max_speed(value):
	MAX_SPEED = value

func set_jumping(value):
	is_jumping = value
	
func freeze_attack(value):
	freeze_attack = value

func _on_AnimationPlayer_Upper_animation_finished(anim_name):
	var lower_anim = animation_manager_lower.current_animation
	animation_manager_upper.play_animation(lower_anim)
	var lower_anim_position = animation_manager_lower.get_current_animation_position() 
	animation_manager_upper.seek(lower_anim_position, true)

