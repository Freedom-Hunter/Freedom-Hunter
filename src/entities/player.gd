extends "entity.gd"


onready var camera_node = get_node("../yaw/pitch/camera")
onready var yaw_node = get_node("../yaw")
onready var weapon_node = get_node("weapon/sword")
onready var weapon_animation = get_node("weapon/animation")
onready var audio_node = get_node("audio")
onready var interact_node = get_node("interact")
onready var offset = yaw_node.get_translation().y
onready var hud = get_node("/root/game/hud")
var inventory = preload("res://scene/inventory.tscn").instance()


const SPRINT_USE = 5
const SPRINT_REGENERATION = 4
const SPEED = 5
const JUMP = 5
const SPRINT_SPEED = 7.5

#multiplayer
var local = true

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
	inventory.init([null_item, potion, firework, barrel], 30)
	inventory.set_pos(Vector2(1370, 200))
	inventory.set_name("player_inventory")

func _ready():
	if local:
		set_fixed_process(true)
		set_process_input(true)

func sort_by_distance(a, b):
	var dist_a = (get_global_transform().origin - a.get_global_transform().origin).length()
	var dist_b = (get_global_transform().origin - b.get_global_transform().origin).length()
	return dist_a < dist_b

func get_interact():
	var interacts = interact_node.get_overlapping_areas()
	for i in interacts:
		if not i.is_in_group("interact"):
			interacts.erase(i)
	if interacts.size() > 0:
		interacts.sort_custom(self, "sort_by_distance")
		return interacts[0]
	return null

func _input(event):
	if Input.is_action_pressed("player_scroll_next") and not Input.is_action_pressed("camera_rotation_lock"):
		inventory.activate_next()
		hud.update_items()
	elif Input.is_action_pressed("player_scroll_back") and not Input.is_action_pressed("camera_rotation_lock"):
		inventory.activate_prev()
		hud.update_items()
	elif event.is_action_pressed("player_use"):
		inventory.use_active_item()
		hud.update_items()
	elif Input.is_action_pressed("player_interact"):
		if not hud.get_node("notification/animation").is_playing():
			var interact = get_interact()
			if interact != null:
				interact.get_node("..").interact(self)

func add_item(item):
	var remainder = inventory.add_item(item)
	if local:
		hud.update_items()
		if remainder > 0:
			hud.notify("You got %d out of %d %s" % [remainder - item.quantity, item.quantity, item.name])
		else:
			hud.notify("You got %d %s" % [item.quantity, item.name])
	return remainder

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

func pause_player():
	set_process_input(false)
	set_fixed_process(false)
	camera_node.set_process_input(false)

func resume_player():
	if local:
		set_process_input(true)
		set_fixed_process(true)
		camera_node.set_process_input(true)

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
	if hud.get_node("analog").is_visible():
		var d = hud.get_node("analog").direction
		direction = d.y * camera.basis.z + d.x * camera.basis.x
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

	direction.x = direction.x * speed
	direction.y = jump
	direction.z = direction.z * speed

	# Player collision and physics
	move_entity(delta)

	if Input.is_action_pressed("player_attack_left"):
		if not weapon_animation.is_playing():
			weapon_animation.play("left_attack_0")
			if networking.multiplayer:
				networking.peer.local_player_left_attack()
	if Input.is_action_pressed("player_attack_right"):
		if not weapon_animation.is_playing():
			weapon_animation.play("right_attack_0")
			if networking.multiplayer:
				networking.peer.local_player_right_attack()

	# Camera follows the player
	yaw_node.set_translation(get_translation() + Vector3(0, offset, 0))
