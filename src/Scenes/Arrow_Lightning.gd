extends RigidBody

func _ready():
	pass # Replace with function body.

func _process(delta):
	if translation.y < -5:
		queue_free()
