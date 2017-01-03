extends KinematicBody

onready var global = get_node("/root/global")
onready var networking = get_node("/root/networking")

const MAX_SLOPE_ANGLE = deg2rad(40)
const MAX_STAMINA = 200

var hp = 0
var max_hp = 0
var regenerable_hp = 0
var stamina = 0
var max_stamina = 0

var hp_regeneration = 1
var hp_regeneration_interval = 5

var time_hit = 0

var direction = Vector3()
var velocity = Vector3()
var floor_vel = Vector3()

var on_floor = false
var jumping = false
var dodging = false
var running = false

var interpolation_factor  # how fast we interpolate rotations
var animation_path
var animation_node

func _init(_hp, _stamina, anim_path, interp=15):
	hp = _hp
	max_hp = _hp
	stamina = _stamina
	max_stamina = _stamina
	animation_path = anim_path
	interpolation_factor = interp

func _ready():
	set_process(true)
	animation_node = get_node(animation_path)
	animation_node.connect("finished", self, "_on_animation_finished")

func move_entity(delta, gravity=true):
	var ti = get_global_transform()

	velocity.x = direction.x
	if gravity:
		velocity.y += global.gravity * delta
	if jumping:
		velocity.y += direction.y
	velocity.z = direction.z

	if dodging:
		velocity.z *= 3
		velocity.x *= 3

	look_ahead(delta)
	var motion = move(velocity * delta)
	on_floor = false

	if is_colliding():
		var n = get_collision_normal()
		if acos(n.dot(Vector3(0, 1, 0))) < MAX_SLOPE_ANGLE:
			on_floor = true
			floor_vel = get_collider_velocity()
			move(floor_vel * delta)
#			if collider extends KinematicBody:
#				floor_vel = collider.get_global_transform().origin
#				move_to(floor_vel)
#			else:
#				floor_vel = get_collider_velocity()
#				move(floor_vel * delta)
			var fall = (int((-velocity.y) - 10) ^ 2) * 5
			if fall > 0:
				damage(fall, 0.5)
			motion = n.slide(motion)
			velocity = n.slide(velocity)
			motion = move(motion)
		else:
			motion = n.slide(motion)
			move(motion)

	if on_floor:
		jumping = false

	if networking.multiplayer:
		var tf = get_global_transform()
		var dist = tf.origin - ti.origin
		var yaw_diff = abs(atan2(dist.x, dist.z))

		if dist.length() > 0.01 and yaw_diff > 0.01:
			networking.peer.local_entity_move(get_name(), tf)

func look_ahead(delta):
	if direction.length() != 0:
		var target = Vector3(direction.x, 0, direction.z).normalized()
		target = -(get_transform().basis.z).linear_interpolate(target, delta * interpolation_factor)
		target += get_global_transform().origin
		look_at(target, Vector3(0, 1, 0))

func _on_animation_finished():
	dodging = false
	running = false

func get_pos():
	return get_global_transform().origin

func die():
	print("%s died" % get_name())
	hp = 0
	regenerable_hp = 0
	set_process(false)
	animation_node.disconnect("finished", self, "_on_animation_finished")

func damage(dmg, reg):
	if hp > 0:
		time_hit = 0
		hp -= dmg
		regenerable_hp = int(hp + dmg * reg)
		if hp <= 0:
			die()
		else:
			print("%s damaged by %s" % [get_name(), dmg])
	else:
		print(get_name(), " is already dead")

func attack(attack_name):
	animation_node.play(attack_name)

func increase_max_stamina(amount):
	if max_stamina + amount <= MAX_STAMINA:
		max_stamina += amount

func _process(delta):
	time_hit += delta
	if time_hit > hp_regeneration_interval:
		time_hit = 0
		if regenerable_hp - hp > 0:
			hp += hp_regeneration

