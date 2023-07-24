extends CharacterBody3D
class_name Entity


const MAX_STAMINA = 200

# HP Health Points
var hp: int = 100
var hp_max: int = 100
var hp_regenerable: int = 100
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
var direction := Vector3()

# Other
var interpolation_factor: float = 10.  # how fast we sample rotations
var previous_origin := Vector3()

@onready var animation_tree := $AnimationTree
@onready var state_machine: AnimationNodeStateMachinePlayback = $AnimationTree["parameters/playback"]
@onready var movement_state_machine: AnimationNodeStateMachinePlayback = $AnimationTree["parameters/movement/playback"]



func _str() -> String:
	return """---\n
		Entity %s\n
		\tHP: %d/%d/%d\n
		\tStamina: %d/%d\n
		\t%s\n
		---""" % [name, hp, hp_regenerable, hp_max, stamina, stamina_max,
			"Dead" if $AnimationTree["parameters/conditions/dead"] else "Alive"]


func _ready():
	hp_changed.connect(func(hp, hp_reg, hp_max):
		if multiplayer.has_multiplayer_peer() and is_multiplayer_authority():
			rpc("_update_hp", hp, hp_reg, hp_max))
	stamina_changed.connect(func(stam, max):
		if multiplayer.has_multiplayer_peer() and is_multiplayer_authority():
			rpc("_update_stamina", stam, max))
	hp_changed.emit(hp, hp_regenerable, hp_max)
	stamina_changed.emit(stamina, stamina_max)


func dodge():
	if is_on_floor() and direction != Vector3() and stamina >= dodge_stamina:
		stamina -= dodge_stamina
		stamina_changed.emit(stamina, stamina_max)
		$AnimationTree["parameters/movement/conditions/dodging"] = true


func jump():
	if is_on_floor() and stamina >= jump_stamina:
		stamina -= jump_stamina
		velocity.y += jump_speed
		stamina_changed.emit(stamina, stamina_max)
		$AnimationTree["parameters/movement/conditions/jumping"] = true


func run():
	if stamina > 0:
		$AnimationTree["parameters/conditions/idle"] = false
		$AnimationTree["parameters/conditions/moving"] = true
		$AnimationTree["parameters/movement/conditions/running"] = true
		$AnimationTree["parameters/movement/conditions/walking"] = false


func walk():
	$AnimationTree["parameters/conditions/idle"] = false
	$AnimationTree["parameters/conditions/moving"] = true
	$AnimationTree["parameters/movement/conditions/walking"] = true
	$AnimationTree["parameters/movement/conditions/running"] = false


func stop():
	if not $AnimationTree["parameters/movement/conditions/dodging"]:
		$AnimationTree["parameters/conditions/moving"] = false
	$AnimationTree["parameters/conditions/idle"] = true
	$AnimationTree["parameters/movement/conditions/running"] = false
	$AnimationTree["parameters/movement/conditions/walking"] = false


func rest():
	stop()
	$AnimationTree["parameters/conditions/resting"] = true


func is_idle() -> bool:
	return $AnimationTree["parameters/conditions/idle"]


func is_dead() -> bool:
	return $AnimationTree["parameters/conditions/dead"]


func move_entity(delta: float, gravity:bool=true):
	var ti = get_transform()
	var vi = velocity

	velocity.x = direction.x
	if gravity:
		velocity.y += global.gravity * delta
	velocity.z = direction.z

	if stamina <= 0:
		stamina = 0
		rest()

	var current_state = state_machine.get_current_node()

	match current_state:
		"rest":
			velocity *= Vector3(0, 1, 0)
			direction = Vector3()
		"attack":
			velocity *= Vector3(attack_speed, 1, attack_speed)
		"movement":
			match movement_state_machine.get_current_node():
				"walk-loop":
					velocity *= Vector3(walk_speed, 1, walk_speed)
				"run-loop":
					if direction != Vector3():
						velocity *= Vector3(run_speed, 1, run_speed)
						stamina -= run_stamina * delta
						stamina_changed.emit(stamina, stamina_max)
				"dodge":
					velocity *= Vector3(dodge_speed, 1, dodge_speed)
				"jump":
					if Input.get_action_strength("player_run") > 0:
						velocity *= Vector3(run_speed, 1, run_speed)
					else:
						velocity *= Vector3(walk_speed, 1, walk_speed)
		_:
			velocity *= Vector3(0, 1, 0)

	look_ahead(delta)
	#print(direction, velocity, current_state, movement_state_machine.get_current_node())
	move_and_slide()

	if is_on_wall():
		velocity.y = -1

	if is_on_floor():
		$AnimationTree["parameters/movement/conditions/jumping"] = false
		velocity.y = 0

	var acceleration = (velocity - vi).length()
	if acceleration > 10:
		damage(pow(acceleration / 10, 7), 0.5)

	if multiplayer.has_multiplayer_peer() and is_multiplayer_authority():
		var tf = get_transform()
		var dist = (tf.origin - ti.origin).length()
		var rotx = (tf.basis.x - ti.basis.x).length()
		var roty = (tf.basis.y - ti.basis.y).length()
		var rotz = (tf.basis.z - ti.basis.z).length()

		if dist > 0.01 or rotx > 0.001 or roty > 0.001 or rotz > 0.001:
			#rpc("transform", tf)
			pass


func look_ahead(delta):
	if direction:
		var target = Vector3(direction.x, 0, direction.z).normalized()
		target = -(get_transform().basis.z).lerp(target, delta * interpolation_factor)
		target += get_global_transform().origin
		look_at(target, Vector3(0, 1, 0))


func _on_animation_tree_animation_finished(anim_name: String):
	if "attack" in anim_name:
		$AnimationTree["parameters/conditions/attacking"] = false
		stop()
	match anim_name:
		"dodge":
			$AnimationTree["parameters/movement/conditions/dodging"] = false
			walk()
		"rest":
			$AnimationTree["parameters/conditions/resting"] = false
		"drink":
			$AnimationTree["parameters/conditions/drinking"] = false


func get_pos():
	return get_global_transform().origin


@rpc func die():
	if not $AnimationTree["parameters/conditions/dead"]:
		if multiplayer.has_multiplayer_peer():
			rpc("died")
		else:
			died()
	else:
		print(get_name(), " is already dead")


@rpc("any_peer", "call_local") func died():
	print("%s died" % [name])
	$AnimationTree["parameters/conditions/dead"] = true
	state_machine.travel("death")
	hp = 0
	hp_regenerable = 0
	velocity = Vector3()
	direction = Vector3()
	set_process(false)


@rpc func respawn():
	set_transform(Transform3D())
	hp = hp_max
	hp_regenerable = hp_max
	stamina = stamina_max
	$AnimationTree["parameters/conditions/dead"] = false
	$AnimationTree["parameters/movement/conditions/dodging"] = false
	$AnimationTree["parameters/movement/conditions/jumping"] = false
	$AnimationTree["parameters/movement/conditions/running"] = false
	$AnimationTree["parameters/conditions/resting"] = false
	$AnimationTree["parameters/conditions/drinking"] = false
	$AnimationTree["parameters/conditions/idle"] = true
	state_machine.travel("idle-loop")
	set_process(true)
	if multiplayer.has_multiplayer_peer() and is_multiplayer_authority():
		rpc("respawn")
	hp_changed.emit(hp, hp_regenerable, hp_max)
	stamina_changed.emit(stamina, stamina_max)


func get_defence():
	return 0


func heal(amount):
	hp += amount
	if hp > hp_max:
		hp = hp_max
	hp_changed.emit(hp, hp_regenerable, hp_max)


@rpc("call_remote") func _update_hp(hp, hp_regenerable, hp_max):
	self.hp = hp
	self.hp_regenerable = hp_regenerable
	self.hp_max = hp_max


@rpc("call_remote") func _update_stamina(stamina, stamina_max):
	self.stamina = stamina
	self.stamina_max = stamina_max


func damage(dmg, reg, weapon=null, entity=null):
	if hp > 0:
		time_hit = 0
		var defence = get_defence()
		hp -= dmg - defence
		hp_regenerable = int(hp + dmg * reg)
		if weapon != null and entity != null:
			print("%s was hit by %s with %s and lost %s - %s = %s health points. HP: %s (+%s)" % [name, entity.name, weapon.name, dmg, defence, dmg - defence, hp, hp_regenerable])
		else:
			print("%s lost %s - %s = %s health points. HP: %s (+%s)" % [name, dmg, defence, dmg - defence, hp, hp_regenerable])
		if hp <= 0:
			die()
		hp_changed.emit(hp, hp_regenerable, hp_max)
	else:
		prints(get_name(), "is already dead")


func attack(attack_name):
	$AnimationTree["parameters/conditions/attacking"] = true


func stamina_max_increase(amount):
	if stamina_max + amount <= MAX_STAMINA:
		stamina_max += amount
		stamina = stamina_max
		stamina_changed.emit(stamina, stamina_max)


func stamina_natural_regeneration(delta, current_state):
	match current_state:
		"idle-loop":
			stamina += stamina_regeneration * delta
		"rest":
			stamina += stamina_regeneration * delta * 2
	if stamina > stamina_max:
		stamina = stamina_max
	stamina_changed.emit(stamina, stamina_max)


func stamina_boost(amount):
	stamina += amount
	if stamina > stamina_max:
		stamina = stamina_max
	stamina_changed.emit(stamina, stamina_max)


func hp_natural_regeneration(delta, current_state):
	if not current_state in ["dodge", "run", "jump"]:
		time_hit += delta
		if time_hit > hp_regeneration_interval:
			time_hit = 0
			if hp_regenerable > hp:
				hp += hp_regeneration
				hp_changed.emit(hp, hp_regenerable, hp_max)


func _process(delta):
	var current_state = state_machine.get_current_node()
	hp_natural_regeneration(delta, current_state)
	stamina_natural_regeneration(delta, current_state)
