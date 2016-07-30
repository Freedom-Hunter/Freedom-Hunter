extends "entity.gd"

const SPEED = 2
const DISTANCE = 100

onready var player_node = get_node("../player/body")
var yaw = 0
var target_yaw = 0
#var rand_time = 0

# @override from entity.gd
func die():
	set_fixed_process(false)
	rotate_z(PI/2)

func _ready():
	hp = 5
	set_fixed_process(true)

func _fixed_process(delta):
	var origin = get_global_transform().origin
	var player_origin = player_node.get_global_transform().origin
	var distance_from_player = player_origin - origin
	var vely = velocity.y

	if distance_from_player.length() < DISTANCE and get_transform().basis.z.dot(distance_from_player) > 0:
		if distance_from_player.length() > 7.5:
			velocity = distance_from_player.normalized() * SPEED
		else:
			velocity = Vector3()
			if not get_node("animation").is_playing():
				get_node("animation").play("attack")
		target_yaw = atan2(distance_from_player.x, distance_from_player.z)
		if target_yaw < 0:
			target_yaw += 2 * PI
	#elif rand_time > 5:
	#	velocity = Vector3(rand_range(-1, 1), vely, rand_range(-1, 1))
	#	target_yaw = atan2(velocity.x, velocity.z)
	#	rand_time = 0
	#print(target_yaw)
	else:
		velocity *= 0.25
	
	var cw
	var ccw
	if yaw < target_yaw:
		ccw = target_yaw - yaw
		cw = 2*PI - target_yaw + yaw
	else:
		ccw = 2*PI - yaw + target_yaw
		cw = yaw - target_yaw
	if cw < ccw:
		yaw -= cw * delta
	else:
		yaw += ccw * delta
	set_rotation(Vector3(0, yaw, 0))
	
	velocity.y = vely
	velocity.y += global.gravity * delta
	
	move_entity(delta)
	
	#rand_time += delta
