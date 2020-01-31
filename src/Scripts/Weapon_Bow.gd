extends Spatial

var arrows_scene_list = {}

var current_arrow
var player_armature
var player_skeleton
var bone_spine_id

var prev_global_transform
var is_aimed setget is_aimed
var time = 0

var test_sprite_transform_orig

func _ready():
	current_arrow ="Arrow_Lightning"

	player_skeleton = get_node("../..")
	player_armature = get_node("../../..")
	bone_spine_id = player_skeleton.find_bone("Bip001 Spine0")
	
	prev_global_transform = global_transform
	is_aimed = false
	
	#test_sprite_transform_orig = $Sprite3D.transform

func _physics_process(delta):
	aim_arrow(delta)
	
func load_arrows(arrows):
	for arrow in arrows:
		arrows_scene_list[arrow] = preload("res://src/Scenes/" + "Arrow_Lightning" + ".tscn")

func switch_arrow(arrow):
	current_arrow = arrow

func aim_arrow(delta):
	if is_aimed == false:
		time = 0
		return
	
	time += delta	
	if time < 0.5:
		return
	time = 0

	#var node = shoot_arrow()
	#node.get_node("Mesh_Instance").set_visible(false)
	#node.get_node("CollisionShape").set_disabled(true)
	
	#time += delta
	#var pos = Helper.projectile_motion(0.35, 0.15 , 7, time, 0.5)
	#var pos3 = Vector3(pos.x, pos.y, 0)
	
	#var angle = player_skeleton.get_bone_pose(bone_spine_id).basis.get_rotation_quat().get_euler().y

	#$Sprite3D.rotation.x = -global_transform.basis.get_rotation_quat().get_euler().x
	#$Sprite3D.rotation.y = 0
	#$Sprite3D.rotation.z = 0
	#$Sprite3D.translate(pos3)
	#$Sprite3D.translation.x = 0
	#print($Sprite3D.rotation, ":", pos3)
	
func shoot_arrow():
	var clone = arrows_scene_list[current_arrow].instance()
	var scene_root = get_tree().root.get_children()[0]
	scene_root.add_child(clone)
	
	clone.global_transform = global_transform
	
	var spine_rotation = Quat(player_skeleton.get_bone_pose(bone_spine_id).basis)
	var x = -spine_rotation.y + player_armature.rotation.x
	var y = -spine_rotation.x + player_armature.rotation.y

	clone.linear_velocity = clone.linear_velocity.rotated( Vector3(1, 0, 0), x )
	clone.linear_velocity = clone.linear_velocity.rotated( Vector3(0, 1, 0), y )
	clone.angular_velocity = clone.angular_velocity.rotated( Vector3(0, 1, 0), y)
	
	clone.rotation = Vector3(x, y, 0)
	
	#if is_aimed == false:
		#clone.get_node("Trajectory_Guide").set_visible(false)
	return clone

func is_aimed(value):
	is_aimed = value
