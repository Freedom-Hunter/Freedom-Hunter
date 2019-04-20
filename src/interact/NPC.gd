extends Spatial

const Player = preload("res://src/entities/player.gd")
const Inventory = preload("res://src/inventory.gd")
const Shop = preload("res://src/interface/shop.gd")

onready var shop: Shop = preload("res://data/scenes/interface/shop.tscn").instance()
onready var hud = get_node("/root/hud/margin/view")

const Potion = preload("res://src/items/potion.gd")
const Firework = preload("res://src/items/firework.gd")
const Barrel = preload("res://src/items/barrel.gd")
const Whetstone = preload("res://src/items/whetstone.gd")
const Meat = preload("res://src/items/meat.gd")

var player:Player = null

func _ready():
	shop.set_items([
		Potion.new("Potion",       preload("res://data/images/items/potion.png"),   10, self, 20),
		Firework.new("Firework",   preload("res://data/images/items/firework.png"), 10, self),
		Barrel.new("Barrel",       preload("res://data/images/items/barrel.png"),    5,  self),
		Whetstone.new("Whetstone", preload("res://data/images/items/whetstone.png"), 10, self, 20),
		Meat.new("Meat",           preload("res://data/images/items/meat.png"),      5,  self, 25)
	], 10)

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

func _process(delta):
	for body in $interact.get_overlapping_bodies():
		if body.is_in_group("player"):
			transform = transform.looking_at(body.transform.origin, Vector3.UP)
