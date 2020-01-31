extends Node

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
			
func projectile_motion(init_x, init_y, velocity, delta, angle, gravity = 9.8):
	var x = init_x + velocity * delta * cos(angle)
	var y = init_y + velocity * delta * sin(angle) - gravity / 2 * delta * delta
	return Vector2(x, y)
