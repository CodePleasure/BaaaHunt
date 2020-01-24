extends AnimationPlayer

var valid_change_states = {
	"Idle": ["Walking", "Running"],
	"Walking": ["Idle", "Running", "Attack_01", "Attack_02"],
	"Running": ["Idle", "Walking", "Attack_01", "Attack_02"],
	"Jumping": ["Idle", "Walking", "Running", "Attack_01", "Attack_02"],
	"Attack_01": ["Idle"],
	"Attack_02": ["Idle"],
}

var animation_speeds = {
	"Idle": 1.75,
	"Walking": 1,
	"Running": 1.75,
	"Jumping": 1.5,
	"Attack_01": 1.75,
	"Attack_02": 1,
}

var current_state = null
var callback_function = null

func _ready():
	play_animation("Idle")
	connect("animation_finished", self, "animation_ended")

func in_valid_next_states(animation_name):
	if not has_animation(animation_name):
		return false
		
	if not animation_name in valid_change_states:
		return false
	
	return current_state in valid_change_states[animation_name]

func set_animation(animation_name):
	if not in_valid_next_states(animation_name):
		return false
		
	play_animation(animation_name)
	return true

func play_animation(animation_name, blend = 0.15):
	play(animation_name, blend, animation_speeds[animation_name])
	current_state = animation_name

func animation_callback():
	if callback_function == null:
		print("AnimationPlayer_Manager.gd -- WARNING: No callback function for the animation to call!")
	else:
		callback_function.call_func()

func animation_ended(anim_name):
	if anim_name == "Jumping":
		play_animation("Idle")
	elif anim_name == "Attack_01":
		play_animation("Idle")
	elif anim_name == "Attack_02":
		play_animation("Idle")