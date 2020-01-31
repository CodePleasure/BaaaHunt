extends Spatial

export var INITIAL_X = 0.35
export var INITIAL_Y = 0.15
export var ARROW_SPEED = 1.6
export var ARROW_DAMAGE = 15

const KILL_TIMER = 5
var timer = 0

var hit_something = false

var trajectory_particle = preload("res://src/Scenes/Trajectory_Guide.tscn")

var particles = []
var trajectory_container_node
var show_trajectory = false

func _ready():
	trajectory_container_node = get_parent().get_node("Trajectory_Container")

	$Area.connect("body_entered", self, "collided")

func _physics_process(delta):
	timer += delta * 0.6
	if timer >= KILL_TIMER:
		queue_free()
	
	if hit_something:
		return
		
	var pos = Helper.projectile_motion(INITIAL_X, INITIAL_Y, ARROW_SPEED, timer, rotation.x)
	
	var xrot = -pos.y - PI / 2
	$Arrow.rotation.x = clamp(xrot, -PI/2, -PI/4)
	translate(Vector3(0, pos.y, pos.x))
	
	#update_particle_locations()

func update_particle_locations():
	for p in particles:
		p.queue_free()
	particles.clear()
	
	var i = 0
	while i < 20:
		var clone = trajectory_particle.instance()
		trajectory_container_node.add_child(clone)
		particles.append(clone)
		
		clone.translation = transform.origin
		clone.scale = Vector3(.1, .1, .1)
		
		var time = i*0.2
		var z = 0.35 + ARROW_SPEED * time * cos(-rotation.x)
		var y = 0.15 + ARROW_SPEED * time * sin(-rotation.x) - 9.81 / 2 * time * time
	
		clone.translate(Vector3(0, y, z))
		
		i += 1
		
func collided(body):
	if hit_something == false:
		if body.has_method("arrow_hit"):
			body.arrow_hit(ARROW_DAMAGE, global_transform)
	
	hit_something = true
