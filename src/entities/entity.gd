extends KinematicBody
class_name Entity


const MAX_SLOPE_ANGLE = deg2rad(40)
const MAX_STAMINA = 200

# HP Health Points
puppet var hp: int = 100
var hp_max: int = 100
puppet var hp_regenerable: int = 100
var hp_regeneration: int = 1
var hp_regeneration_interval: int = 5
signal hp_changed(hp, hp_reg, hp_max)

# Stamina
var stamina: float = 100
var stamina_max: int = 100
var stamina_regeneration: float = 4
signal stamina_changed(stamina, stamina_max)

# Dodge
var dodge_stamina: float = 10
var dodge_speed: float = 8

# Jump
var jump_stamina: float = 15
var jump_speed: float = 10

# Run
var run_stamina: float = 5
var run_speed: float = 7.5

# Walk
var walk_speed: float = 5

# Attack
var attack_speed: float = 1

# Time since latest damage
var time_hit: float = 0

# State
var direction: Vector3 = Vector3()
var velocity: Vector3 = Vector3()

# Other
var interpolation_factor: float = 10  # how fast we interpolate rotations
var previous_origin: Vector3 = Vector3()

onready var state_machine: AnimationNodeStateMachinePlayback = $AnimationTree["parameters/playback"]


func _str() -> String:
	return """---\n
		Entity %s\n
		\tHP: %d/%d/%d\n
		\tStamina: %d/%d\n
		\t%s\n
		---""" % [name, hp, hp_regenerable, hp_max, stamina, stamina_max,
			"Dead" if $AnimationTree["parameters/conditions/dead"] else "Alive"]


func _ready():
	$AnimationPlayer.connect("animation_finished", self, "_on_animation_finished")
	$AnimationPlayer.rpc_config("play", MultiplayerAPI.RPC_MODE_PUPPET)
	rset_config("transform", MultiplayerAPI.RPC_MODE_PUPPET)
	emit_signal("hp_changed", hp, hp_regenerable, hp_max)
	emit_signal("stamina_changed", stamina, stamina_max)


func dodge():
	if is_on_floor() and direction != Vector3() and stamina >= dodge_stamina:
		stamina -= dodge_stamina
		emit_signal("stamina_changed", stamina, stamina_max)
		$AnimationTree["parameters/conditions/dodging"] = true


func jump():
	if is_on_floor() and stamina >= jump_stamina:
		stamina -= jump_stamina
		velocity.y += jump_speed
		emit_signal("stamina_changed", stamina, stamina_max)
		$AnimationTree["parameters/conditions/jumping"] = true


func run():
	if stamina > 0:
		$AnimationTree["parameters/conditions/idle"] = false
		$AnimationTree["parameters/conditions/running"] = true
		$AnimationTree["parameters/conditions/walking"] = false


func walk():
	$AnimationTree["parameters/conditions/idle"] = false
	$AnimationTree["parameters/conditions/running"] = false
	$AnimationTree["parameters/conditions/walking"] = true


func stop():
	$AnimationTree["parameters/conditions/idle"] = true
	$AnimationTree["parameters/conditions/running"] = false
	$AnimationTree["parameters/conditions/walking"] = false


func rest():
	stop()
	$AnimationTree["parameters/conditions/resting"] = true


func move_entity(delta: float, gravity:bool=true):
	var ti = get_transform()

	var old_velocity = velocity

	velocity.x = direction.x
	if gravity:
		velocity.y += global.gravity * delta
	velocity.z = direction.z

	if stamina <= 0:
		stamina = 0
		rest()

	var current_state = state_machine.get_current_node()
	print(current_state)
	if current_state == "jump":
		if Input.get_action_strength("player_run") > 0:
			velocity *= Vector3(run_speed, 1, run_speed)
		else:
			velocity *= Vector3(walk_speed, 1, walk_speed)
	elif current_state == "rest":
		velocity *= Vector3(0, 1, 0)
		direction = Vector3()
	elif current_state == "dodge":
		velocity *= Vector3(dodge_speed, 1, dodge_speed)
	elif current_state == "run-loop":
		if direction != Vector3():
			velocity *= Vector3(run_speed, 1, run_speed)
			stamina -= run_stamina * delta
			emit_signal("stamina_changed", stamina, stamina_max)
	elif current_state.find("attack") != -1:
		velocity *= Vector3(attack_speed, 1, attack_speed)
	elif current_state == "walk-loop":
		velocity *= Vector3(walk_speed, 1, walk_speed)
	else:
		velocity *= Vector3(0, 1, 0)

	look_ahead(delta)

	# Vector3 linear_velocity, Vector3 floor_normal=Vector3(), bool stop_on_slope=false,
	# int max_slides=4, float floor_max_angle=0.785398, bool infinite_inertia=true 
	velocity = move_and_slide(velocity, Vector3.UP, true, 4, MAX_SLOPE_ANGLE, true)

	if is_on_wall():
		velocity.y = -1

	if is_on_floor():
		$AnimationTree["parameters/conditions/jumping"] = false
		velocity.y = 0

	var acceleration = (velocity - old_velocity).length()
	if acceleration > 10:
		damage(pow(acceleration / 10, 7), 0.5)

	if get_tree().has_network_peer() and is_network_master():
		var tf = get_transform()
		var dist = (tf.origin - ti.origin).length()
		var rotx = (tf.basis.x - ti.basis.x).length()
		var roty = (tf.basis.y - ti.basis.y).length()
		var rotz = (tf.basis.z - ti.basis.z).length()

		if dist > 0.01 or rotx > 0.001 or roty > 0.001 or rotz > 0.001:
			rset_unreliable("transform", tf)


func look_ahead(delta):
	if direction:
		var target = Vector3(direction.x, 0, direction.z).normalized()
		target = -(get_transform().basis.z).linear_interpolate(target, delta * interpolation_factor)
		target += get_global_transform().origin
		look_at(target, Vector3(0, 1, 0))


func _on_animation_finished(anim):
	print("end anim " + anim)
	if anim == "dodge":
		$AnimationTree["parameters/conditions/dodging"] = false
	elif anim == "rest":
		$AnimationTree["parameters/conditions/resting"] = false
	elif anim == "drink":
		$AnimationTree["parameters/conditions/drinking"] = false


func get_pos():
	return get_global_transform().origin


master func die():
	if not $AnimationTree["parameters/conditions/dead"]:
		if get_tree().has_network_peer():
			rpc("died")
		else:
			died()
	else:
		print(get_name(), " is already dead")


sync func died():
	print("%s died" % [get_name()])
	$AnimationTree["parameters/conditions/dead"] = true
	state_machine.travel("dead")
	hp = 0
	hp_regenerable = 0
	velocity = Vector3()
	direction = Vector3()
	set_process(false)


puppet func respawn():
	set_transform(Transform())
	hp = hp_max
	hp_regenerable = hp_max
	stamina = stamina_max
	$AnimationTree["parameters/conditions/dead"] = false
	$AnimationTree["parameters/conditions/dodging"] = false
	$AnimationTree["parameters/conditions/jumping"] = false
	$AnimationTree["parameters/conditions/running"] = false
	$AnimationTree["parameters/conditions/resting"] = false
	$AnimationTree["parameters/conditions/drinking"] = false
	$AnimationTree["parameters/conditions/idle"] = true
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


func attack(attack_name):
	$AnimationTree["parameters/conditions/" + attack_name] = true


func stamina_max_increase(amount):
	if stamina_max + amount <= MAX_STAMINA:
		stamina_max += amount
		stamina = stamina_max
		emit_signal("stamina_changed", stamina, stamina_max)


func stamina_natural_regeneration(delta, current_state):
	if current_state != "dodge" and (current_state != "run-loop" or direction == Vector3()):
		if current_state == "rest":
			delta *= 2
		stamina += stamina_regeneration * delta
		if stamina > stamina_max:
			stamina = stamina_max
		emit_signal("stamina_changed", stamina, stamina_max)


func stamina_boost(amount):
	stamina += amount
	if stamina > stamina_max:
		stamina = stamina_max
	emit_signal("stamina_changed", stamina, stamina_max)


func hp_natural_regeneration(delta, current_state):
	if not current_state in ["dodge", "run", "jump"]:
		time_hit += delta
		if time_hit > hp_regeneration_interval:
			time_hit = 0
			if hp_regenerable > hp:
				hp += hp_regeneration
				emit_signal("hp_changed", hp, hp_regenerable, hp_max)


func _process(delta):
	var current_state = state_machine.get_current_node()
	hp_natural_regeneration(delta, current_state)
	stamina_natural_regeneration(delta, current_state)
