extends KinematicBody

const SPEED = 2
const DISTANCE = 10

onready var target_node = get_node("../player/body")
var velocity = Vector3()
var rotation = Vector3()
var rand_time = 0
var hp = 2

func _ready():
	set_fixed_process(true)

func _fixed_process(delta):
	var distance = target_node.get_global_transform().origin - get_global_transform().origin
	var vely = velocity.y
	if distance.length() < DISTANCE:
		velocity = distance.normalized() * SPEED
		var target = target_node.get_global_transform().origin
		target.y = get_global_transform().origin.y
		rotation = rotation.linear_interpolate(target, delta)
		look_at(rotation, Vector3(0, 1, 0))
	elif rand_time > 5:
		velocity = Vector3(rand_range(-1, 1), get_global_transform().origin.y, rand_range(-1, 1))
		set_rotation(Vector3(0, Vector2(velocity.z, velocity.x).angle(), 0))
		rand_time = 0
	
	velocity.y = vely
	velocity.y -= 9.81 * delta
	
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
		get_node("CollisionShape").free()
		rotate_x(PI/2)
