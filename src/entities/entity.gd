extends KinematicBody

onready var global = get_node("/root/global")
onready var networking = get_node("/root/networking")

const MAX_SLOPE_ANGLE = deg2rad(40)
const MAX_STAMINA = 200

slave var hp = 0
var max_hp = 0
slave var regenerable_hp = 0
var stamina = 0
var max_stamina = 0

var hp_regeneration = 1
var hp_regeneration_interval = 5

var time_hit = 0

var direction = Vector3()
var velocity = Vector3()

var jumping = false
var dodging = false
var running = false
var dead = false

var interpolation_factor  # how fast we interpolate rotations

var animation_node
var audio_node

func _init(_hp, _stamina, interp=15):
	hp = _hp
	max_hp = _hp
	stamina = _stamina
	max_stamina = _stamina
	interpolation_factor = interp

func _ready():
	animation_node = find_node("entity_animation")
	animation_node.connect("animation_finished", self, "_on_animation_finished")
	audio_node = find_node("entity_audio")
	rset_config("transform", MultiplayerAPI.RPC_MODE_SLAVE)

func move_entity(delta, gravity=true):
	var ti = get_transform()

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
	var remainder = move_and_slide(velocity, Vector3(0, 1, 0), true, 0.05, 4, MAX_SLOPE_ANGLE)

	if is_on_floor():
		jumping = false
		var fall = (int((-velocity.y) + global.gravity) ^ 2) * 5
		if fall > 0:
			damage(fall, 0.5)
		velocity.y = 0

	if get_tree().has_network_peer() and is_network_master():
		var tf = get_transform()
		var dist = (tf.origin - ti.origin).length()
		var rotx = (tf.basis.x - ti.basis.x).length()
		var roty = (tf.basis.y - ti.basis.y).length()
		var rotz = (tf.basis.z - ti.basis.z).length()

		if dist > 0.01 or rotx > 0.001 or roty > 0.001 or rotz > 0.001:
			rset_unreliable("transform", tf)

func look_ahead(delta):
	if direction.length() != 0:
		var target = Vector3(direction.x, 0, direction.z).normalized()
		target = -(get_transform().basis.z).linear_interpolate(target, delta * interpolation_factor)
		target += get_global_transform().origin
		look_at(target, Vector3(0, 1, 0))

func _on_animation_finished(anim):
	dodging = false
	running = false

func get_pos():
	return get_global_transform().origin

master func die():
	if not dead:
		if get_tree().has_network_peer():
			rpc("died")
		else:
			died()
	else:
		print(get_name(), " is already dead")

sync func died():
	print("%s died" % get_name())
	dead = true
	hp = 0
	regenerable_hp = 0
	velocity = Vector3()
	direction = Vector3()
	set_process(false)

slave func respawn():
	set_transform(Transform())
	hp = max_hp
	regenerable_hp = 0
	stamina = max_stamina
	dead = false
	dodging = false
	jumping = false
	set_process(true)
	if get_tree().has_network_peer() and is_network_master():
		rpc("respawn")

func get_defence():
	return 0

func damage(dmg, reg, weapon=null, entity=null):
	if hp > 0:
		time_hit = 0
		var defence = get_defence()
		hp -= dmg - defence
		regenerable_hp = int(hp + dmg * reg)
		if get_tree().has_network_peer():
			rset("hp", hp)
			rset("regenerable_hp", regenerable_hp)
		if weapon != null and entity != null:
			print("%s was hit by %s with %s and lost %s - %s = %s health points. HP: %s (+%s)" % [name, entity.name, weapon.name, dmg, defence, dmg - defence, hp, regenerable_hp])
		else:
			print("%s lost %s - %s = %s health points. HP: %s (+%s)" % [name, dmg, defence, dmg - defence, hp, regenerable_hp])
		if hp <= 0:
			die()
	else:
		prints(get_name(), "is already dead")

sync func attack(attack_name):
	if animation_node.has_animation(attack_name):
		if not animation_node.is_playing() or animation_node.get_current_animation() != attack_name:
			animation_node.play(attack_name)

func increase_max_stamina(amount):
	if max_stamina + amount <= MAX_STAMINA:
		max_stamina += amount
		stamina = max_stamina

func _process(delta):
	time_hit += delta
	if time_hit > hp_regeneration_interval:
		time_hit = 0
		if regenerable_hp - hp > 0:
			hp += hp_regeneration

func audio(stream):
	audio_node.stream = stream
	audio_node.play()
