extends "entity.gd"

onready var yaw_node = get_node("/root/game/yaw")
onready var camera_node = yaw_node.get_node("pitch/camera")
onready var camera_offset = yaw_node.get_translation().y
onready var interact_node = get_node("interact")

onready var hud = get_node("/root/game/hud")
onready var onscreen = hud.get_node("onscreen")

const STAMINA_REGENERATION = 4
const SPRINT_STAMINA = 5
const DODGE_STAMINA = 10
const DODGE_SPEED = 6
const WALK_SPEED = 5
const SPRINT_SPEED = 7.5

var equipment = {"weapon": null, "armour": {"head": null, "torso": null, "rightarm": null, "leftarm": null, "leg": null}}
var inventory = preload("res://data/scenes/inventory.tscn").instance()


func _init().(150, 100):
	pass

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		inventory.free()

func set_equipment(model, bone, _name=null):
	var skel = get_node("model/Armature/Skeleton")
	for node in skel.get_children():
		if node is BoneAttachment:
			if node.get_bone_name() == bone:
				node.add_child(model)
				if _name != null:
					node.set_name(name)
				return
	var ba = BoneAttachment.new()
	if _name != null:
		ba.set_name(_name)
	ba.set_bone_name(bone)
	ba.add_child(model)
	skel.add_child(ba)

func _ready():
	# TEST CODE
	equipment.weapon = load("res://data/scenes/equipment/weapon/lasersword/laser_sword.tscn").instance()
	set_equipment(equipment.weapon, "weapon_L", "weapon")

	# Item test
	var Item = preload("res://src/items/usable_item.gd")
	var Potion = preload("res://src/items/potion.gd")
	var Firework = preload("res://src/items/firework.gd")
	var Barrel = preload("res://src/items/barrel.gd")
	var Whetstone = preload("res://src/items/whetstone.gd")

	var null_item = Item.new("None",           preload("res://data/images/items/null.png"),      0,  0, 0, self, true)
	var potion    = Potion.new("Potion",       preload("res://data/images/items/potion.png"),    10, self, 20)
	var firework  = Firework.new("Firework",   preload("res://data/images/items/firework.png"),  10, self)
	var barrel    = Barrel.new("Barrel",       preload("res://data/images/items/barrel.png"),    5,  self)
	var whetstone = Whetstone.new("Whetstone", preload("res://data/images/items/whetstone.png"), 10, self, 20)

	inventory.init([null_item, potion, firework, barrel, whetstone], 30)
	inventory.set_position(Vector2(1370, 200))
	inventory.set_name("player_inventory")
	resume_player()

func sort_by_distance(a, b):
	var dist_a = (get_global_transform().origin - a.get_global_transform().origin).length()
	var dist_b = (get_global_transform().origin - b.get_global_transform().origin).length()
	return dist_a < dist_b

func get_nearest_interact():
	var areas = interact_node.get_overlapping_areas()
	var interacts = []
	for area in areas:
		if area.is_in_group("interact"):
			interacts.append(area)
	if interacts.size() > 0:
		interacts.sort_custom(self, "sort_by_distance")
		return interacts[0]
	return null

func interact_with(interact):
	if interact != null and not hud.get_node("notification/animation").is_playing():
		interact.get_parent().interact(self)

func interact_with_nearest():
	interact_with(get_nearest_interact())

func _input(event):
	if event.is_action_pressed("player_scroll_next") and not Input.is_action_pressed("camera_rotation_lock"):
		inventory.activate_next()
	elif event.is_action_pressed("player_scroll_back") and not Input.is_action_pressed("camera_rotation_lock"):
		inventory.activate_prev()
	elif event.is_action_pressed("player_use"):
		inventory.use_active_item()
	elif Input.is_action_pressed("player_interact"):
		interact_with_nearest()

func add_item(item):
	item = item.clone()
	item.player = self
	var remainder = inventory.add_item(item)
	if not get_tree().has_network_peer() or is_network_master():
		if remainder > 0:
			hud.notify("You can't carry more than %d %s" % [item.max_quantity, item.name])
		else:
			hud.notify("You got %d %s" % [item.quantity, item.name])
	return remainder

func drop_item(item):
	var drop = $drop_item.get_global_transform()
	item.set_global_transform(drop)
	get_parent().add_child(item)

func heal(amount):
	hp += amount
	if hp > max_hp:
		hp = max_hp

func get_defence():
	var defence = 0
	for piece in equipment.armour.values():
		if piece != null:
			defence += piece.strength
	return defence

sync func died():
	.died()
	animation_node.play("death")
	audio(preload("res://data/sounds/hit.wav"))
	set_process(false)
	set_physics_process(false)
	set_process_input(false)
	if not get_tree().has_network_peer() or is_network_master():
		hud.prompt_respawn()
	$shape.disabled = true

func respawn():
	.respawn()
	resume_player()
	$shape.disabled = false

func pause_player():
	direction = Vector3()
	set_process_input(false)
	set_physics_process(false)
	set_process(false)
	animation_node.play("idle")

func resume_player():
	var enable = not get_tree().has_network_peer() or is_network_master()
	set_process_input(enable)
	set_physics_process(enable)
	set_process(true)

func _process(delta):
	if dead:
		return
	var anim = animation_node.get_current_animation()
	var playing = animation_node.is_playing()
	if playing and anim.find("attack") != -1:
		return
	if direction.length() != 0:
		if dodging:
			if anim != "dodge" or not playing:
				animation_node.play("dodge", 0.5)
		elif running:
			if anim != "run" or not playing:
				animation_node.play("run", 0.5)
		elif anim != "walk" or not playing:
			animation_node.play("walk", 0.5)
	elif anim in ["walk", "run", "death"] or not playing:
		animation_node.play("idle", 0.5)

func _physics_process(delta):
	if not dodging:
		direction = Vector3(0, 0, 0)
		var jump = 0
		var camera = camera_node.get_global_transform()
		# Player movements
		var speed = WALK_SPEED
		if Input.is_action_pressed("player_forward"):
			direction -= Vector3(camera.basis.z.x, 0, camera.basis.z.z)
		if Input.is_action_pressed("player_backward"):
			direction += Vector3(camera.basis.z.x, 0, camera.basis.z.z)
		if Input.is_action_pressed("player_left"):
			direction -= Vector3(camera.basis.x.x, 0, camera.basis.x.z)
		if Input.is_action_pressed("player_right"):
			direction += Vector3(camera.basis.x.x, 0, camera.basis.x.z)

		if onscreen.is_visible():
			var d = onscreen.direction
			direction = d.y * camera.basis.z + d.x * camera.basis.x

		running = Input.is_action_pressed("player_run") and direction != Vector3() and stamina > SPRINT_STAMINA * delta
		if Input.is_action_pressed("player_run") and direction != Vector3():
			stamina -= SPRINT_STAMINA * delta
			if stamina < 0:
				stamina = 0
			else:
				speed = SPRINT_SPEED
		elif stamina < max_stamina:
			stamina += STAMINA_REGENERATION * delta
			if stamina > max_stamina:
				stamina = max_stamina

		if Input.is_action_pressed("player_dodge") and is_on_floor() and direction != Vector3() and stamina >= DODGE_STAMINA:
			if running:
				if not jumping:
					jumping = true
					jump = SPRINT_SPEED
					stamina -= DODGE_STAMINA
					#$"audio".play("jump")
			elif not dodging:
				dodging = true
				speed = DODGE_SPEED
				stamina -= DODGE_STAMINA
				#$"audio".play("dodge")

		direction = direction.normalized()
		direction.x = direction.x * speed
		direction.y = jump
		direction.z = direction.z * speed

	# Player collision and physics
	move_entity(delta)

	if Input.is_action_pressed("player_attack_left"):
		if get_tree().has_network_peer():
			rpc("attack", "left_attack_0")
		else:
			attack("left_attack_0")
	if Input.is_action_pressed("player_attack_right"):
		if get_tree().has_network_peer():
			rpc("attack", "right_attack_0")
		else:
			attack("right_attack_0")

	# Camera follows the player
	yaw_node.set_translation(get_translation() + Vector3(0, camera_offset, 0))
