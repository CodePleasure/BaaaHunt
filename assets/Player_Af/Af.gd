extends KinematicBody

export var JUMP_SPEED = 10
export var GRAVITY = -32

export var AIM_ROTATION_SPEED = 1
export var AIM_WIDTH_X = PI/5
export var AIM_WIDTH_Y = 1.55

const PLAYER_ROTATION_ADJUSTMENT = -0.075
const AIM_ROTATION_RATIO = 0.075
const AIM_ROTATION_Y_ADJUST = 0.12

var MAX_SPEED = 6
var ACCEL = 12
var DEACCEL = 12

var is_animation_changeable = true
var is_jumping = false
var is_aiming = false
var freeze_position = false
var freeze_attack = false

var model_scale

var input_movement_vector = Vector2()
var input_movement_vector_normalized = Vector2()
var input_aim_rotation_vector = Vector2()
var dir = Vector3()
var vel = Vector3()

var animation_manager_upper
var animation_manager_lower

var arrow_scene = preload("res://assets/Arrows/Arrow_Lightning/Arrow_Light.tscn")

var skeleton
var bone_rotation_spine
var bone_rotation_pelvis
var tm = 0

func _ready():
	model_scale = $Armature.scale
	
	animation_manager_upper = $Armature/Skeleton/AnimationPlayer_Upper
	animation_manager_lower = $Armature/Skeleton/AnimationPlayer_Lower

	skeleton = $Armature/Skeleton
	bone_rotation_spine = skeleton.find_bone("Bip001 Spine0")
	bone_rotation_pelvis = skeleton.find_bone("Bip001 Pelvis")

	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN) 
	
func _physics_process(delta):
	process_input(delta)
	process_model_animation(delta)
	process_model_rotation(delta)
	process_model_aim_rotation(delta)
	process_model_direction(delta)
	process_model_movement(delta)

func process_input(delta):
	input_movement_vector = get_joy_dir_vector("joypad_axis_left_up", "joypad_axis_left_down", "joypad_axis_left_left", "joypad_axis_left_right")
	
	if input_movement_vector == Vector2(0,0):
		if Input.is_key_pressed(KEY_W):
			input_movement_vector.y -= 1
		if Input.is_key_pressed(KEY_S):
			input_movement_vector.y += 1
		if Input.is_key_pressed(KEY_A):
			input_movement_vector.x += 1
		if Input.is_key_pressed(KEY_D):
			input_movement_vector.x -= 1

	input_movement_vector_normalized = input_movement_vector.normalized()
	
	input_aim_rotation_vector = get_joy_dir_vector("joypad_axis_right_up", "joypad_axis_right_down", "joypad_axis_right_left", "joypad_axis_right_right")

func get_joy_dir_vector(up, down, left, right):
	var vec = Vector2()
	if Input.is_action_pressed(up):
		vec.y -= Input.get_action_strength(up)
	if Input.is_action_pressed(down):
		vec.y += Input.get_action_strength(down) 
	if Input.is_action_pressed(left):
		vec.x += Input.get_action_strength(left)
	if Input.is_action_pressed(right):
		vec.x -= Input.get_action_strength(right)
	return vec

func shoot_arrow():
	var clone = arrow_scene.instance()
	var scene_root = get_tree().root.get_children()[0]
	scene_root.add_child(clone)
	
	clone.global_transform = $"Armature/Skeleton/Bip001 R HandBoneAttachment/Bow".global_transform
	clone.scale = Vector3(0.5,0.5,0.5)
	var spine_rotation = Quat(skeleton.get_bone_pose(bone_rotation_spine).basis)
	var x = -spine_rotation.y + $Armature.rotation.x
	var y = -spine_rotation.x + $Armature.rotation.y
	clone.rotation = Vector3(x, y, 0)

func process_model_animation(delta):
	if Input.is_action_just_pressed("movement_jump"):
		play_animation("Jumping")
		
	if Input.is_action_pressed("action_attack"):
		play_animation("Attack_Aim_01")
	elif Input.is_action_just_released("action_attack"):
		play_animation("Release_Arrow_01")
	
	if is_to_move() == true:
		if is_joy_strength_for_walking():
			play_animation("Walking")
		else:
			play_animation("Running")
	else:
		play_animation("Idle")

func play_animation(animation_name):
	animation_manager_lower.set_animation(animation_name)
	animation_manager_upper.set_animation(animation_name)

func process_model_rotation(delta):
	if is_to_move() == false:
		return
	
	if freeze_position == true:
		return

	var rotation_rad = xy2rad(input_movement_vector_normalized) + $Camera.rotation.y
	var rotation_vec = Vector3(0, rotation_rad + PLAYER_ROTATION_ADJUSTMENT, 0)
	$Armature.rotation = rotation_vec
	$Armature.orthonormalize()
	$Armature.scale = model_scale

func process_model_aim_rotation(delta):
	var rotate_dir

	if is_aiming:
		var x = clamp(input_aim_rotation_vector.x, -AIM_WIDTH_X, AIM_WIDTH_X)
		var y = clamp(-input_aim_rotation_vector.y, -AIM_WIDTH_Y, AIM_WIDTH_Y)
		y += (x / -AIM_WIDTH_Y * 0.12)
		rotate_dir = Quat(Basis(Vector3(x, 0, 0))) * Quat(Basis(Vector3(0, y, 0)))
	else:
		rotate_dir = Quat(skeleton.get_bone_pose(bone_rotation_pelvis).basis)
	
	var bone_t_basis = Quat(skeleton.get_bone_pose(bone_rotation_spine).basis)
	var t = bone_t_basis.slerp(rotate_dir, AIM_ROTATION_SPEED * AIM_ROTATION_RATIO)
	skeleton.set_bone_pose(bone_rotation_spine, t)

func process_model_direction(delta):
	dir = Vector3()
	
	if freeze_position == true:
		return

	dir += -get_transform().basis.z * input_movement_vector_normalized.y
	dir += get_transform().basis.x * input_movement_vector_normalized.x

func process_model_movement(delta):
	if freeze_position == true:
		return

	var player_dir = dir
	player_dir = player_dir.rotated(Vector3(0, 1, 0), $Camera.rotation.y)
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

func is_joy_strength_for_walking():
	if abs(input_movement_vector.x) + abs(input_movement_vector.y) <= 0.9:
		return true
	return false
	
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

func set_aiming(value):
	is_aiming = value

func _on_AnimationPlayer_Upper_animation_finished(anim_name):
	if anim_name == "Attack_Aim_01":
		play_animation("Attack_Aim_Idle_01")
	else:
		var lower_anim = animation_manager_lower.current_animation
		animation_manager_upper.play_animation(lower_anim)
		var lower_anim_position = animation_manager_lower.get_current_animation_position() 
		animation_manager_upper.seek(lower_anim_position, true)
