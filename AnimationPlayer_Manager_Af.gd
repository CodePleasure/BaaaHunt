extends AnimationPlayer

var states = {
	"Unarmed Idle 01": [],
	"Standing Idle 01": ["Standing Idle 02 Looking", "Standing Idle 03 Examine", "Standing Run Forward", "Standing To Crouch", "Standing Draw Arrow"],
	"Standing Idle 02 Looking": ["Standing Idle 01", "Standing Run Forward", "Standing To Crouch", "Standing Draw Arrow"],
	"Standing Idle 03 Examine": ["Standing Idle 01", "Standing Run Forward", "Standing To Crouch", "Standing Draw Arrow"],
	"Standing Run Forward": ["Standing Idle 01", "Standing To Crouch", "Standing Draw Arrow"],
	
	# Crouch
	"Standing To Crouch": ["Crouch Idle 01", "Crouch Walk Forward", "Crouch To Standing"],
	"Crouch Idle 01": ["Crouch Idle 02 Looking Around", "Crouch Idle 03 Looking Over", "Crouch Walk Forward", "Crouch To Standing"],
	"Crouch Idle 02 Looking Around": ["Crouch Idle 01", "Crouch Walk Forward", "Crouch To Standing"],
	"Crouch Idle 03 Looking Over": ["Crouch Idle 01", "Crouch Walk Forward", "Crouch To Standing"],
	"Crouch Walk Forward": ["Crouch Idle 01", "Crouch To Standing"],
	"Crouch To Standing": ["Standing Idle 01", "Standing Run Forward"],
	
	# Arrow
	"Standing Draw Arrow": ["Standing Aim Idle 01", "Standing Idle 01"],
	"Standing Aim Idle 01": ["Standing Aim Idle 01", "Standing Aim Idle 02 Looking",  "Standing Idle 01"],
	"Standing Aim Idle 02 Looking": ["Standing Aim Idle 01", "Standing Idle 01"],
}
var animation_speeds = {
	"Unarmed Idle 01": 1,
	"Standing Idle 01": 1,
	"Standing Idle 02 Looking": 1,
	"Standing Idle 03 Examine": 1,
	"Standing Run Forward": 1.25,
	"Standing Run Forward Stop": 1,
	
	# Crouch
	"Standing To Crouch": 2,
	"Crouch Idle 01": 1,
	"Crouch Idle 02 Looking Around": 1,
	"Crouch Idle 03 Looking Over": 1,
	"Crouch To Standing": 2,
	"Crouch Walk Forward": 1.25,
	
	# Arrow
	"Standing Draw Arrow": 1.5,
	"Standing Aim Idle 01": 1,
	"Standing Aim Idle 02 Looking": 1
}

var current_state = null
var callback_function = null
var randi_generator = RandomNumberGenerator.new()

func _ready():
	set_animation("Standing Idle 01")
	connect("animation_finished", self, "animation_ended")

func set_animation(animation_name, backwards = false):
	if animation_name == current_state:
		return true

	if has_animation(animation_name):
		if current_state != null:
			var possible_animations = states[current_state]
			
			if animation_name in possible_animations:
				current_state = animation_name
				if backwards == false:
					play(animation_name, 0.25, animation_speeds[animation_name])
				else:
					play_backwards(animation_name, 0.25)
				return true
			else:
				return true
		else:
			current_state = animation_name
			if backwards == false:
				play(animation_name, 0.25, animation_speeds[animation_name])
			else:
				play_backwards(animation_name, 0.25)
			return true
	
	return false

func animation_callback():
	if callback_function == null:
		print("AnimationPlayer_Manager.gd -- WARNING: No callback function for the animation to call!")
	else:
		callback_function.call_func()

func animation_ended(anim_name):
	if anim_name == "Standing Idle 01":
		var possible_actions = [states[current_state][0], states[current_state][1]]
		var next = randomize_next_animation(possible_actions)
		set_animation(next)
	elif anim_name == "Standing Idle 02 Looking":
		set_animation("Standing Idle 01")
	elif anim_name == "Standing Idle 03 Examine":
		set_animation("Standing Idle 01")
	elif anim_name == "Standing Run Forward Stop":
		set_animation("Standing Idle 01")
	elif anim_name == "Standing To Crouch":
		set_animation("Crouch Idle 01")
	elif anim_name == "Crouch Idle 01":
		var possible_actions = [states[current_state][0], states[current_state][1]]
		var next = randomize_next_animation(possible_actions)
		set_animation(next)
	elif anim_name == "Crouch Idle 02 Looking Around":
		set_animation("Crouch Idle 01")
	elif anim_name == "Crouch Idle 03 Looking Over":
		set_animation("Crouch Idle 01")
	elif anim_name == "Crouch To Standing":
		set_animation("Standing Idle 01")
	elif anim_name == "Standing Draw Arrow":
		set_animation("Standing Aim Idle 01")
	elif anim_name == "Standing Aim Idle 01":
		var possible_actions = [states[current_state][0], states[current_state][1]]
		var next = randomize_next_animation(possible_actions)
		set_animation(next)
	
func randomize_next_animation(animations):
	var rand = randi_generator.randi_range(0, animations.size() - 1)
	return animations[rand]