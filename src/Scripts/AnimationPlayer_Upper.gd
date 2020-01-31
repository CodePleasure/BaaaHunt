extends "res://src/Scripts/AnimationPlayer_Base.gd"

func _ready():
	Valid_Change_States =  {
		"Idle": ["Walking", "Running"],
		"Walking": ["Idle", "Running"],
		"Running": ["Idle", "Walking"],
		"Jumping": ["Idle", "Walking", "Running"],
		"Attack_Aim_01": ["Idle", "Jumping", "Walking", "Running"],
		"Attack_Aim_Idle_01": ["Attack_Aim_01"],
		"Release_Arrow_01": ["Attack_Aim_01", "Attack_Aim_Idle_01"],
	}

	play_animation("Idle")

func animation_callback():
	if callback_function == null:
		print("AnimationPlayer_Manager.gd -- WARNING: No callback function for the animation to call!")
	else:
		callback_function.call_func()
