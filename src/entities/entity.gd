extends KinematicBody

onready var global = get_node("/root/global")
onready var networking = get_node("/root/networking")

const MAX_SLOPE_ANGLE = deg2rad(40)

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

var interpolation_factor = 15  # how fast we interpolate rotations

# Multiplayer
var ti
var tf

func _ready():
	set_process(true)

func init(hp, stamina):
	self.hp = hp
	self.max_hp = hp
	self.stamina = stamina
	self.max_stamina = stamina

func move_entity(delta, gravity=true):
	if networking.multiplayer:
		ti = get_global_transform()

	velocity.x = direction.x
	if gravity:
		velocity.y += global.gravity * delta
	if jumping:
		velocity.y += direction.y
	velocity.z = direction.z

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
			var fall = int((-velocity.y) - 10)
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
		tf = get_global_transform()
		var dist = tf.origin - ti.origin
		var yaw_diff = abs(atan2(dist.x, dist.z))

		if dist.length() > 0.01 and yaw_diff > 0.01:
			if self extends preload("res://src/entities/player.gd"):
				networking.peer.local_player_move(tf)
			elif networking.is_server():
				networking.peer.local_monster_move(get_name(), tf)

func look_ahead(delta):
	if direction.length() != 0:
		var target = Vector3(direction.x, 0, direction.z).normalized()
		target = -(get_transform().basis.z).linear_interpolate(target, delta * interpolation_factor)
		target += get_global_transform().origin
		look_at(target, Vector3(0, 1, 0))

func get_pos():
	return get_global_transform().origin

func die():
	print("%s died" % get_name())
	hp = 0
	regenerable_hp = 0
	set_process(false)

func damage(dmg, reg):
	if hp > 0:
		print("%s: damage of %s" % [get_name(), dmg])
		time_hit = 0
		hp -= dmg
		regenerable_hp = int(hp + dmg * reg)
		if hp <= 0:
			die()
	else:
		print(get_name(), " is already dead")

func _process(delta):
	time_hit += delta
	if time_hit > hp_regeneration_interval:
		time_hit = 0
		if regenerable_hp - hp > 0:
			hp += hp_regeneration
