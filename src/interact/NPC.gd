class_name NPCShop
extends Spatial

const Shop = preload("res://src/interface/shop.gd")

onready var shop: Shop = preload("res://data/scenes/interface/shop.tscn").instance()
onready var hud = get_node("/root/hud/margin/view")


# Player with whom we are interacting with
var player: Player = null
# Classical NPC behaviour: rotate randomly and stare void for some time
var random_angle: float
var random_basis: Basis
var stare_wait: float
var stare_time: float


func new_random_stare():
	random_angle = rand_range(0, 2*PI)
	random_basis = global_transform.basis.rotated(Vector3.UP, random_angle)
	stare_wait = rand_range(1, 10)
	stare_time = 0


func _ready():
	shop.set_items([
		Potion.new("Potion",       preload("res://data/images/items/potion.png"),    10, 20),
		Firework.new("Firework",   preload("res://data/images/items/firework.png"),  10),
		Barrel.new("Barrel",       preload("res://data/images/items/barrel.png"),    5),
		Whetstone.new("Whetstone", preload("res://data/images/items/whetstone.png"), 10, 20),
		Meat.new("Meat",           preload("res://data/images/items/meat.png"),      5, 25)
	], 10)
	new_random_stare()


func interact(new_player: Player, node):
	assert(player == null)
	player = new_player
	player.pause_player()
	get_viewport().get_camera().set_process_input(false)
	hud.open_inventories([shop, player.inventory])
	for shop_item in shop.shop_items:
		shop_item.connect("buy", player, "buy_item")
	$ohayou.play()
	yield(hud.get_node("inventory"), "popup_hide")
	for shop_item in shop.shop_items:
		shop_item.disconnect("buy", player, "buy_item")
	player.resume_player()
	get_viewport().get_camera().set_process_input(true)
	player = null


func slerp_look_at(target: Vector3, slerp_factor: float):
	# rotate on Y axis towards target with linear interpolation
	target.y = global_transform.origin.y  # prevent rotations on X axis
	var rot_transform = global_transform.looking_at(target, Vector3.UP)
	global_transform.basis = global_transform.basis.slerp(rot_transform.basis, slerp_factor).orthonormalized()


func _process(delta):
	var min_distance = INF
	var nearest_player = null

	if player != null:
		nearest_player = player
	else:
		for body in $interact.get_overlapping_bodies():
			if body.is_in_group("player"):
				var target: Vector3 = body.global_transform.origin
				var distance = (target - global_transform.origin).length()
				if distance < min_distance:
					min_distance = distance
					nearest_player = body

	if nearest_player != null:
		# rotate towards nearest player
		slerp_look_at(nearest_player.global_transform.origin, delta * 10)
	else:
		# rotate and stare randomly
		global_transform.basis = global_transform.basis.slerp(random_basis, 10 * delta).orthonormalized()
		# CHeck if rotation completed
		var remaining_rotation = abs(global_transform.basis.z.angle_to(random_basis.z))
		if remaining_rotation < deg2rad(5):
			# rotation completed, stare for a while
			stare_time += delta
			if stare_time > stare_wait:
				# It's boring! Stare somewhere else
				new_random_stare()
