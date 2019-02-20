extends KinematicBody

onready var global = get_node("/root/global")
#onready var networking = get_node("/root/networking")

const MAX_SLOPE_ANGLE = deg2rad(40)
const MAX_STAMINA = 200

# HP Health Points
puppet var hp = 0
var hp_max = 0
puppet var hp_regenerable = 0
var hp_regeneration = 1
var hp_regeneration_interval = 5
signal hp_changed(hp, hp_reg, hp_max)

# Stamina
var stamina = 0
var stamina_max = 0
var stamina_regeneration = 4
signal stamina_changed(stamina, stamina_max)

# Dodge
puppet var dodging = false
var dodge_stamina = 10
var dodge_speed = 6

# Jump
var jumping = false
var jump_stamina = 15
var jump_speed = 10

# Run
puppet var running = false
var run_stamina = 5
var run_speed = 7.5

# Walk
var walk_speed = 5

# Time since latest damage
var time_hit = 0

# State
var dead = false
var direction = Vector3()
var velocity = Vector3()

# Other
var interpolation_factor  # how fast we interpolate rotations
var animation_node
var previous_origin = Vector3()


func _init(_hp=100, _hp_reg=null, _hp_max=null, _stamina=100, _stamina_max=null, interp=15):
	hp = _hp
	hp_regenerable = _hp if _hp_reg == null else _hp_reg
	hp_max = _hp if _hp_max == null else _hp_max
	stamina = _stamina
	stamina_max = _stamina if _stamina_max == null else _stamina_max
	interpolation_factor = interp

func _ready():
	animation_node = find_node("entity_animation")
	animation_node.connect("animation_finished", self, "_on_animation_finished")
	rset_config("transform", MultiplayerAPI.RPC_MODE_PUPPET)
	emit_signal("hp_changed", hp, hp_regenerable, hp_max)
	emit_signal("stamina_changed", stamina, stamina_max)

func dodge():
	if not dodging and is_on_floor() and direction != Vector3() and stamina >= dodge_stamina:
		if get_tree().has_network_peer():
			rset_unreliable("dodging", true)
		dodging = true
		stamina -= dodge_stamina
		emit_signal("stamina_changed", stamina, stamina_max)

func jump():
	if not jumping and stamina >= jump_stamina:
		if get_tree().has_network_peer():
			rset_unreliable("jumping", true)
		jumping = true
		stamina -= jump_stamina
		velocity.y += jump_speed
		emit_signal("stamina_changed", stamina, stamina_max)

func run():
	if not running and direction != Vector3() and stamina > 0:
		if get_tree().has_network_peer():
			rset_unreliable("running", true)
		running = true

func walk():
	if get_tree().has_network_peer():
		rset_unreliable("running", false)
	running = false

func move_entity(delta: float, gravity:bool=true):
	var ti = get_transform()

	var old_velocity = velocity

	velocity.x = direction.x
	if gravity:
		velocity.y += global.gravity * delta
	velocity.z = direction.z

	if stamina <= 0:
		running = false

	if jumping:
		if running:
			velocity.x *= run_speed
			velocity.z *= run_speed
		else:
			velocity.x *= walk_speed
			velocity.z *= walk_speed
	elif dodging:
		velocity *= dodge_speed
	elif running:
		velocity *= run_speed
		stamina -= run_stamina * delta
		emit_signal("stamina_changed", stamina, stamina_max)
	else:
		velocity *= walk_speed

	look_ahead(delta)

	# Vector3 linear_velocity, Vector3 floor_normal=Vector3(), bool stop_on_slope=false,
	# int max_slides=4, float floor_max_angle=0.785398, bool infinite_inertia=true 
	var remainder = move_and_slide(velocity, Vector3.UP, true, 4, MAX_SLOPE_ANGLE, true)

	if is_on_floor():
		if jumping and get_tree().has_network_peer() and is_network_master():
			rset_unreliable("jumping", false)
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
	if anim == "run" and direction != Vector3() and Input.is_action_pressed("player_run"):
		animation_node.play("run") # keep running
	elif anim == "dodge" and running:
		dodging = false
		animation_node.play("run") # keep running
	else:
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
	print("%s died" % [get_name()])
	dead = true
	hp = 0
	hp_regenerable = 0
	velocity = Vector3()
	direction = Vector3()
	set_process(false)

puppet func respawn():
	set_transform(Transform())
	hp = hp_max
	hp_regenerable = 0
	stamina = stamina_max
	dead = false
	dodging = false
	jumping = false
	set_process(true)
	if get_tree().has_network_peer() and is_network_master():
		rpc("respawn")
	emit_signal("hp_changed", hp, hp_regenerable, hp_max)
	emit_signal("stamina_changed", stamina, stamina_max)

func get_defence():
	return 0

func heal(amount):
	hp += amount
	if hp > hp_max:
		hp = hp_max
	emit_signal("hp_changed", hp, hp_regenerable, hp_max)

func damage(dmg, reg, weapon=null, entity=null):
	if hp > 0:
		time_hit = 0
		var defence = get_defence()
		hp -= dmg - defence
		hp_regenerable = int(hp + dmg * reg)
		if get_tree().has_network_peer():
			rset("hp", hp)
			rset("hp_regenerable", hp_regenerable)
		if weapon != null and entity != null:
			print("%s was hit by %s with %s and lost %s - %s = %s health points. HP: %s (+%s)" % [name, entity.name, weapon.name, dmg, defence, dmg - defence, hp, hp_regenerable])
		else:
			print("%s lost %s - %s = %s health points. HP: %s (+%s)" % [name, dmg, defence, dmg - defence, hp, hp_regenerable])
		if hp <= 0:
			die()
		emit_signal("hp_changed", hp, hp_regenerable, hp_max)
	else:
		prints(get_name(), "is already dead")

sync func attack(attack_name):
	if animation_node.has_animation(attack_name):
		if not animation_node.is_playing() or animation_node.get_current_animation() != attack_name:
			animation_node.play(attack_name)

func stamina_max_increase(amount):
	if stamina_max + amount <= MAX_STAMINA:
		stamina_max += amount
		stamina = stamina_max
		emit_signal("stamina_changed", stamina, stamina_max)

func stamina_natural_regeneration(delta):
	if not dodging and not running:
		stamina += stamina_regeneration * delta
		if stamina > stamina_max:
			stamina = stamina_max
		emit_signal("stamina_changed", stamina, stamina_max)

func stamina_boost(amount):
	stamina += amount
	if stamina > stamina_max:
		stamina = stamina_max
	emit_signal("stamina_changed", stamina, stamina_max)

func hp_natural_regeneration(delta):
	if not dodging and not running:
		time_hit += delta
		if time_hit > hp_regeneration_interval:
			time_hit = 0
			if hp_regenerable > hp:
				hp += hp_regeneration
				emit_signal("hp_changed", hp, hp_regenerable, hp_max)

func _process(delta):
	hp_natural_regeneration(delta)
	stamina_natural_regeneration(delta)
