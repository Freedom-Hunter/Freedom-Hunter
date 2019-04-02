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
			var remainder = player.add_item(item)
			if not get_tree().has_network_peer() or player.is_network_master():
				if remainder > 0:
					player.hud.notify("You can't carry more than %d %s" % [item.max_quantity, item.name])
				else:
					player.hud.notify("You got %d %s" % [item.quantity, item.name])
			break
		last += item.rarity
	quantity -= 1;
	if quantity <= 0:
		queue_free()
