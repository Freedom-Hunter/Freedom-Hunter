extends Area

var Potion = preload("res://src/items/potion.gd")
var Firework = preload("res://src/items/firework.gd")
var Barrel = preload("res://src/items/barrel.gd")

var potion = Potion.new()
var firework = Firework.new()
var barrel = Barrel.new()

var obtainable = [barrel, firework, potion]
var quantity = rand_range(2, 10)
var rarity = 0


func _init():
	potion.init(self, preload("res://media/items/potion.png"), "Potion", 1, 25)
	firework.init(self, preload("res://media/items/firework.png"), "Firework", 1)
	barrel.init(self, preload("res://media/items/barrel.png"), "Barrel", 1)
	for i in obtainable:
		rarity += i.rarity

func interact(player):
	var rand = randi() % rarity
	var last = 0
	for i in obtainable:
		if last <= rand and rand < last + i.rarity:
			print("add ", i.name)
			player.add_item(i)
			break
		last += i.rarity
	quantity -= 1;
	if quantity <= 0:
		queue_free()
