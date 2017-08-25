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

var jumping = false
var dodging = false
var running = false
var dead = false
var local = true  # for multiplayer

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
	animation_node.connect("animation_finished", self, "_on_animation_finished")

func move_entity(delta, gravity=true):
	velocity.x = direction.x
	if gravity:
		velocity.y += global.gravity * delta
	if jumping:
		velocity.y += direction.y
	velocity.z = direction.z

	if dodging:
		velocity.z *= 3
		velocity.x *= 3

	var n = Vector3(0, 1, 0)
	look_ahead(delta)
	velocity = move_and_slide(velocity, n)

	if is_on_floor():
		jumping = false

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

func die():
	if not dead:
		print("%s died" % get_name())
		dead = true
		hp = 0
		regenerable_hp = 0
		set_process(false)
		animation_node.disconnect("animation_finished", self, "_on_animation_finished")
		if networking.multiplayer and local:
			networking.peer.local_entity_died(get_name())
	else:
		print(get_name(), " is already dead")

func respawn():
	set_transform(Transform())
	hp = max_hp
	regenerable_hp = 0
	stamina = max_stamina
	dead = false
	set_process(true)
	if networking.multiplayer and local:
		networking.peer.local_entity_respawn(get_name())
	animation_node.connect("animation_finished", self, "_on_animation_finished")

func get_defence():
	return 0

func damage(dmg, reg):
	if hp > 0:
		time_hit = 0
		var defence = get_defence()
		hp -= (dmg - defence)
		regenerable_hp = int(hp + dmg * reg)
		print("%s damaged by %s - %s = %s" % [get_name(), dmg, defence, dmg - defence])
		if hp <= 0:
			die()
		elif networking.multiplayer and local:
			networking.peer.local_entity_damage(get_name(), hp, regenerable_hp)

func attack(attack_name):
	if animation_node.get_current_animation() != attack_name and animation_node.has_animation(attack_name):
		if networking.multiplayer and local:
			networking.peer.local_entity_attack(get_name(), attack_name)
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

