extends Node

var hud_anim

var obtainable = []
var quantity = 0
var rarity = 0

func init():

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
