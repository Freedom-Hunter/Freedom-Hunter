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
var max_items = 30

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
	var dist_a = (get_global_transform().origin - a.get_global_transform().origin).length()
	var dist_b = (get_global_transform().origin - b.get_global_transform().origin).length()
	return dist_a < dist_b

func get_interact():
	var interacts = interact_node.get_overlapping_bodies()
	interacts += interact_node.get_overlapping_areas()
	for i in interacts:
		if not i.is_in_group("interact"):
			interacts.erase(i)
	if interacts.size() > 0:
		interacts.sort_custom(self, "sort_by_distance")
		return interacts[0]
	return null

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
		var interact = get_interact()
		if interact != null:
			interact.interact(self)

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
	.die()
	get_node("audio").play("hit")
	rotate_x(PI/2)
	set_translation(get_translation() + Vector3(0, 0.5, 0))
	set_fixed_process(false)
	set_process_input(false)
	if net and networking.multiplayer:
		networking.peer.local_player_died()

func get_name():  # this script is attached to a node always called body
	return get_parent().get_name()  # parent's name is more meaningful

func _fixed_process(delta):
	direction = Vector3(0, 0, 0)
	var jump = 0
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
		jumping = true
		if run:
			jump = SPRINT_SPEED
			stamina -= 3
		else:
			jump = JUMP
	direction = direction.normalized()

	look_ahead(delta)

	direction.x = direction.x * speed
	direction.y = jump
	direction.z = direction.z * speed

	# Player collision and physics
	move_entity(delta)

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

	if attack and networking.multiplayer:
		networking.peer.local_player_attack(sword_rot)

	# Camera follows the player
	yaw_node.set_translation(get_translation() + Vector3(0, offset, 0))

func _on_sword_body_enter(body):
	if body != self and body extends preload("res://src/entities/entity.gd"):
		body.damage(2, 0.3)
