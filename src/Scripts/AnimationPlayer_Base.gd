extends AnimationPlayer

var Animation_Speeds = {
	"Idle": 1.75,
	"Walking": 1,
	"Running": 1.75,
	"Jumping": 1.5,
	"Attack_Aim_01": 1.75,
	"Attack_Aim_Idle_01": 1.75,
	"Release_Arrow_01": 1.75,
}

var current_state = null
var callback_function = null

var Valid_Change_States = {}

export var MASTER_PLAYBACK_SPEED = 1.0

func _ready():
	pass

func in_valid_next_states(animation_name):
	if not has_animation(animation_name):
		return false
		
	if not animation_name in Valid_Change_States:
		return false
	
	return current_state in Valid_Change_States[animation_name]
	
func set_animation(animation_name, blend = 0.15):
	if not in_valid_next_states(animation_name):
		return false
		
	play_animation(animation_name, blend)
	return true
	
func play_animation(animation_name, blend = 0.15):
	play(animation_name, blend, Animation_Speeds[animation_name] * MASTER_PLAYBACK_SPEED)
	current_state = animation_name
	
