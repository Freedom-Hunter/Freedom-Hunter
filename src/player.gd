extends "entity.gd"

export var SPEED = 2
export var JUMP = 5
export var SPRINT_SPEED = 1.5
const SPRINT_USE = 5
const SPRINT_REGENERATION = 4


onready var camera_node = get_node("../yaw/pitch/camera")
onready var yaw_node = get_node("../yaw")
onready var weapon_node = get_node("weapon/sword")

onready var hud_node = get_node("/root/game/hud")
onready var stamina_node = hud_node.get_node("stamina")
onready var hp_node = hud_node.get_node("hp")
onready var red_hp_node = hud_node.get_node("hp/red_hp")
onready var debug = hud_node.get_node("debug")
onready var audio_node = get_node("audio")

# Player attack
var sword_rot = 0

var items = []
var active_item = 0

func _ready():
	hp = hp_node.get_max()
	max_hp = hp
	stamina = stamina_node.get_max()
	
	# TEST CODE
	var Item = preload("res://src/items/item.gd")
	var null_item = Item.new()
	null_item.init(self, preload("res://scene/items/potion/potion.png"), "None", 0, true)
	var Potion = preload("res://src/items/potion.gd")
	var potion = Potion.new()
	potion.init(self, preload("res://scene/items/potion/potion.png"), "Potion", 10, 25)
	var Firework = preload("res://src/items/firework.gd")
	var firework = Firework.new()
	firework.init(self, preload("res://scene/items/potion/potion.png"), "Potion", 10)
	items = [null_item, potion, firework]

	set_fixed_process(true)
	set_process_input(true)
	print("Start play")

func _input(event):
	if event.is_action_pressed("player_scroll_next"):
		active_item = (active_item + 1) % items.size()
	elif event.is_action_pressed("player_scroll_back"):
		active_item = (active_item - 1) % items.size()
	elif event.is_action_pressed("player_use"):
		items[active_item].use()

func heal(amount):
	hp += amount
	if hp > max_hp:
		hp = max_hp

func die():
	get_node("audio").play("hit")
	rotate_x(PI/2)
	set_translation(get_translation() + Vector3(0, 0.5, 0))
	hud_node.update_values(0, 0, stamina)
	set_fixed_process(false)

func look_where_you_walk(direction, delta):
	if direction.length() != 0:
		var target = Vector3(direction.x, 0, direction.z).normalized()
		target = -(get_transform().basis.z).linear_interpolate(target, delta * 10)
		target += get_global_transform().origin
		look_at(target, Vector3(0, 1, 0))

func _fixed_process(delta):
	var direction = Vector3(0, 0, 0)
	var camera = camera_node.get_global_transform()
	
	# Player movements
	var speed = SPEED
	if Input.is_action_pressed("player_forward"):
		direction -= Vector3(camera.basis.z.x, 0, camera.basis.z.z)
	if Input.is_action_pressed("player_backward"):
		direction += Vector3(camera.basis.z.x, 0, camera.basis.z.z)
	if Input.is_action_pressed("player_left"):
		direction -= Vector3(camera.basis.x.x, 0, camera.basis.x.z)
	if Input.is_action_pressed("player_right"):
		direction += Vector3(camera.basis.x.x, 0, camera.basis.x.z)
	if Input.is_action_pressed("player_run"):
		if stamina > 0:
			speed *= SPRINT_SPEED
			stamina -= SPRINT_USE * delta
	elif stamina < stamina_node.get_max():
		stamina += SPRINT_REGENERATION * delta
	if Input.is_action_pressed("player_jump") and on_floor:
		if Input.is_action_pressed("player_run"):
			velocity.y += JUMP * SPRINT_SPEED
		else:
			velocity.y += JUMP
	direction = direction.normalized()

	look_where_you_walk(direction, delta)

	# Player collision and physics
	velocity.x = direction.x * speed
	velocity.y += global.gravity * delta
	velocity.z = direction.z * speed
	
	move_entity(delta)
	
	if Input.is_action_pressed("player_attack_left"):
		if sword_rot < 87.5:
			sword_rot = fmod(sword_rot + delta*100, 90)
			weapon_node.set_rotation_deg(Vector3(sword_rot, 0, 0))
	if Input.is_action_pressed("player_attack_right"):
		if sword_rot > 2.5:
			sword_rot = fmod(sword_rot - delta*100, 90)
			weapon_node.set_rotation_deg(Vector3(sword_rot, 0, 0))
	
	# Camera follows the player
	yaw_node.set_translation(get_translation() + Vector3(0, 1.5, 0))

	# Print debug info on screen
	debug.set_text("Pos %s" % [get_translation()])
	
	hud_node.update_values(hp, regenerable_hp, stamina)

func _on_sword_body_enter(body):
	if body != self and body extends preload("res://src/entity.gd"):
		body.damage(2, 0.3)
