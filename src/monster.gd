extends KinematicBody

const SPEED = 2
const DISTANCE = 10

onready var player_node = get_node("../player/body")
var velocity = Vector3()
var yaw = 0
var target_yaw = 0
var rand_time = 0
var hp = 2

func _ready():
	set_fixed_process(true)

func _fixed_process(delta):
	var origin = get_global_transform().origin
	var player_origin = player_node.get_global_transform().origin
	var distance_from_player = player_origin - origin
	var vely = velocity.y

	if distance_from_player.length() < DISTANCE and get_transform().basis.z.dot(distance_from_player) > 0:
		velocity = Vector3() #distance_from_player.normalized() * SPEED
		target_yaw = atan2(distance_from_player.x, distance_from_player.z)
	#elif rand_time > 5:
	#	velocity = Vector3(rand_range(-1, 1), vely, rand_range(-1, 1))
	#	target_yaw = atan2(velocity.x, velocity.z)
	#	rand_time = 0
	#print(target_yaw)
	yaw += (target_yaw - yaw) * delta
	set_rotation(Vector3(0, yaw, 0))
	
	velocity.y = vely
	velocity.y += global.gravity * delta
	
	var motion = move(velocity * delta)
	if is_colliding():
		var n = get_collision_normal()
		motion = n.slide(motion)
		velocity = n.slide(velocity)
		move(motion)

	rand_time += delta

func hit():
	hp -= 1
	if hp == 0:
		set_fixed_process(false)
		rotate_z(PI/2)
