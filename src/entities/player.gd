extends "entity.gd"

var SPEED = 5
var JUMP = 5
var SPRINT_SPEED = 7.5
const SPRINT_USE = 5
const SPRINT_REGENERATION = 4

var local = true

onready var camera_node = get_node("../yaw/pitch/camera")
onready var yaw_node = get_node("../yaw")

onready var weapon_node = get_node("weapon/sword")

onready var audio_node = get_node("audio")
onready var interact_node = get_node("interact")

onready var offset = yaw_node.get_translation().y

# Player attack
var sword_rot = 0

var items = []
var active_item = 0

signal got_item
signal used_item

func init(local, hp, stamina):
	.init(hp, stamina)
	self.local = local

	# TEST CODE
	var Item = preload("res://src/items/item.gd")
	var null_item = Item.new()
	null_item.init(self, preload("res://media/items/null.png"), "None", 0, true, 0)
	var Potion = preload("res://src/items/potion.gd")
	var potion = Potion.new()
	potion.init(self, preload("res://media/items/potion.png"), "Potion", 10, 25)
	var Firework = preload("res://src/items/firework.gd")
	var firework = Firework.new()
	firework.init(self, preload("res://media/items/firework.png"), "Firework", 10)
	var Barrel = preload("res://src/items/barrel.gd")
	var barrel = Barrel.new()
	barrel.init(self, preload("res://media/items/barrel.png"), "Barrel", 10)
	items = [null_item, potion, firework, barrel]

func _ready():
	if local:
		set_fixed_process(true)
		set_process_input(true)

func sort_by_distance(a, b):
	var dist_a = (get_translation() - a.get_translation()).length()
	var dist_b = (get_translation() - b.get_translation()).length()
	return dist_a < dist_b

func _input(event):
	if Input.is_action_pressed("player_scroll_next") and not Input.is_action_pressed("camera_rotation_lock"):
		active_item = (active_item + 1) % items.size()
	elif Input.is_action_pressed("player_scroll_back") and not Input.is_action_pressed("camera_rotation_lock"):
		active_item = (active_item - 1) % items.size()
		if active_item < 0:
			active_item = items.size() - 1
	elif event.is_action_pressed("player_use"):
		items[active_item].use()
		emit_signal("used_item", items[active_item])
		if active_item != 0 and items[active_item].quantity <= 0:
			items.remove(active_item)
			active_item = (active_item + 1) % items.size()
	elif event.is_action_pressed("player_interact"):
		var interacts = interact_node.get_overlapping_bodies()
		interacts += interact_node.get_overlapping_areas()
		for i in interacts:
			if not i.is_in_group("interact"):
				interacts.erase(i)
		if interacts.size() > 0:
			interacts.sort_custom(self, "sort_by_distance")
			interacts[0].interact(self)

func add_item(item):
	var found = false
	for e in items:
		if e.name == item.name:
			e.quantity += 1
			found = true
	if not found:
		items.append(item)
	emit_signal("got_item", item)

func heal(amount):
	hp += amount
	if hp > max_hp:
		hp = max_hp

func die(net=true):
	.die(net)
	get_node("audio").play("hit")
	rotate_x(PI/2)
	set_translation(get_translation() + Vector3(0, 0.5, 0))
	set_fixed_process(false)
	set_process_input(false)

func look_where_you_walk(direction, delta):
	if direction.length() != 0:
		var target = Vector3(direction.x, 0, direction.z).normalized()
		target = -(get_transform().basis.z).linear_interpolate(target, delta * 15)
		target += get_global_transform().origin
		look_at(target, Vector3(0, 1, 0))

func get_name():  # this script is attached to a node always called body
	return get_parent().get_name()  # parent's name is more meaningful

func _fixed_process(delta):
	var direction = Vector3(0, 0, 0)
	var camera = camera_node.get_global_transform()

	# Player movements
	var run = Input.is_action_pressed("player_run")
	var speed = SPEED

	if Input.is_action_pressed("player_forward"):
		direction -= Vector3(camera.basis.z.x, 0, camera.basis.z.z)
	if Input.is_action_pressed("player_backward"):
		direction += Vector3(camera.basis.z.x, 0, camera.basis.z.z)
	if Input.is_action_pressed("player_left"):
		direction -= Vector3(camera.basis.x.x, 0, camera.basis.x.z)
	if Input.is_action_pressed("player_right"):
		direction += Vector3(camera.basis.x.x, 0, camera.basis.x.z)
	if run and stamina > 0 and direction != Vector3():
			speed = SPRINT_SPEED
			stamina -= SPRINT_USE * delta
	elif stamina < max_stamina:
			stamina += SPRINT_REGENERATION * delta
			if stamina > max_stamina:
				stamina = max_stamina
	if Input.is_action_pressed("player_jump") and on_floor:
		if run:
			velocity.y += SPRINT_SPEED
		else:
			velocity.y += JUMP
	direction = direction.normalized()


	look_where_you_walk(direction, delta)

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	velocity.y += global.gravity * delta

	# Player collision and physics
	var ti = get_global_transform()
	move_entity(delta)
	var tf = get_global_transform()
	var dist = tf.origin - ti.origin
	var yaw_diff = abs(atan2(dist.x, dist.z))

	if networking.multiplayer and dist.length() > 0.01 and yaw_diff > 0:
		var name = get_parent().get_name()
		if networking.server:
			var pckt = networking.new_packet(networking.CMD_SC_MOVE, {'player': name, 'transform': tf})
			networking.server_broadcast(pckt)
		else:
			var pckt = networking.new_packet(networking.CMD_CS_MOVE, {'player': name, 'transform': tf})
			networking.udp.put_var(pckt)

	var attack = false
	if Input.is_action_pressed("player_attack_left"):
		if sword_rot < 87.5:
			sword_rot = fmod(sword_rot + delta*100, 90)
			weapon_node.set_rotation_deg(Vector3(sword_rot, 0, 0))
			attack = true
	if Input.is_action_pressed("player_attack_right"):
		if sword_rot > 2.5:
			sword_rot = fmod(sword_rot - delta*100, 90)
			weapon_node.set_rotation_deg(Vector3(sword_rot, 0, 0))
			attack = true

	if networking.multiplayer and attack:
		var name = get_parent().get_name()
		if networking.server:
			var pckt = networking.new_packet(networking.CMD_SC_ATTACK, {'player': name, 'rot': sword_rot})
			networking.server_broadcast(pckt)
		else:
			var pckt = networking.new_packet(networking.CMD_CS_ATTACK, {'player': name, 'rot': sword_rot})
			networking.udp.put_var(pckt)

	# Camera follows the player
	yaw_node.set_translation(get_translation() + Vector3(0, offset, 0))

func _on_sword_body_enter(body):
	if body != self and body extends preload("res://src/entities/entity.gd"):
		body.damage(2, 0.3)
