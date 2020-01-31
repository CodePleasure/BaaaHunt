extends Spatial

export var CAMERA_ROTATION_SLOW = 0.0025
export var CAMERA_ROTATION_FAST = 0.025
export var CAMERA_SLERP_TRANSITION_DIFF = 0.025

var player
var skeleton
var armature
var camera_rot_initial
var camera_rot
var is_camera_rotate_ready = false

var player_basis
var player_rot

func _ready():
	player = get_parent()
	skeleton = player.get_node("Armature/Skeleton")

	armature = player.get_node("Armature")
	player_basis = armature.transform.orthonormalized().basis
	player_rot = armature.rotation.y
	
	camera_rot = CAMERA_ROTATION_SLOW
	camera_rot_initial = $Camera_Rear.rotation

func _process(delta):
	process_quick_slerp_camera(delta)
	process_camera_movement(delta)

func process_camera_movement(delta):
	var player_dir = player.dir
	
	var bone_spine_pose = skeleton.get_bone_pose(player.bone_rotation_spine)
	var rotate_dir = Quat(bone_spine_pose.basis)
	
	var camera_rear = $Camera_Rear
	camera_rear.rotation = camera_rot_initial
	camera_rear.rotation.y -= rotate_dir.x / 4

	if camera_rot == CAMERA_ROTATION_SLOW:
		var camera_rotation_trigger = $Camera_Rotation_Trigger
		if player.is_to_move() == true:
			is_camera_rotate_ready = false
			if camera_rotation_trigger.is_stopped() == false:
				camera_rotation_trigger.stop()
			return
		elif is_camera_rotate_ready == false:
			if camera_rotation_trigger.is_stopped() == true:
				camera_rotation_trigger.start()
			return
			
		var abs_z = abs(player_dir.z)
		if abs_z < 0.025:
			player_basis = armature.transform.orthonormalized().basis
			player_rot = armature.rotation.y

	var cam_basis = transform.orthonormalized().basis
	var new_rotation = Quat(cam_basis).slerp(player_basis, camera_rot)

	transform = Transform(new_rotation, Vector3(0, 1, 0))
	rotation.x = 0
	rotation.z = 0

	if abs(rotation.y - player_rot) < CAMERA_SLERP_TRANSITION_DIFF:
		camera_rot = CAMERA_ROTATION_SLOW

func process_quick_slerp_camera(delta):
	if Input.is_action_just_pressed("camera_slerp_fast") == false:
		return
	
	if player.freeze_position == true:
		return

	camera_rot = CAMERA_ROTATION_FAST
	player_basis = armature.transform.orthonormalized().basis
	player_rot = armature.rotation.y

func _on_Camera_Rotation_Trigger_timeout():
	is_camera_rotate_ready = true
