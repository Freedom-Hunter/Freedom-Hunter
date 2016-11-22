extends Node

var obtainable
var quantity
var rarity = 0

func _init(items, quant):
	obtainable = items
	quantity = quant
	for item in obtainable:
		rarity += item.rarity

func interact(player):
	if player != global.local_player:
		return
	var rand = randi() % rarity
	var last = 0
	for item in obtainable:
		if last <= rand and rand < last + item.rarity:
			print("Get item: ", item.name)
			player.add_item(item)
			break
		last += item.rarity
	quantity -= 1;
	if quantity <= 0:
		queue_free()
