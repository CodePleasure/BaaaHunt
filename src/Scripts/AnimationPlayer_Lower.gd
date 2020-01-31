extends "res://src/Scripts/AnimationPlayer_Base.gd"

func _ready():

	Valid_Change_States = {
		"Idle": ["Walking", "Running"],
		"Walking": ["Idle", "Running", "Attack_01", "Attack_02", "Attack_Aim_01", "Attack_Aim_Idle_01", "Release_Arrow_01"], 
		"Running": ["Idle", "Walking", "Attack_01", "Attack_02", "Attack_Aim_01", "Attack_Aim_Idle_01", "Release_Arrow_01"],
		"Jumping": ["Idle", "Walking", "Running", "Attack_01", "Attack_02", "Attack_Aim_01", "Attack_Aim_Idle_01", "Release_Arrow_01"],
		"Attack_Aim_01": ["Idle"],
		"Attack_Aim_Idle_01": ["Attack_Aim_01"],
		"Release_Arrow_01": ["Attack_Aim_01", "Attack_Aim_Idle_01"],
	}

	play_animation("Idle")
	connect("animation_finished", self, "animation_ended")

func animation_callback():
	if callback_function == null:
		print("AnimationPlayer_Manager.gd -- WARNING: No callback function for the animation to call!")
	else:
		callback_function.call_func()

func animation_ended(anim_name):
	if anim_name == "Jumping":
		play_animation("Idle")
	elif anim_name == "Attack_Aim_01":
		play_animation("Attack_Aim_Idle_01")
	elif anim_name == "Release_Arrow_01":
		play_animation("Idle")
