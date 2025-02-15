# SPDX-FileCopyrightText: 2023 Elia Argentieri
#
# SPDX-License-Identifier: GPL-3.0-or-later

extends Node

var obtainable
var quantity
var rarity = 0


func _init(items, quant):
	obtainable = items
	quantity = quant
	for item in obtainable:
		rarity += item.rarity


func interact(player, _node):
	if player != global.local_player:
		return
	var rand = randi() % rarity
	var last = 0
	for item in obtainable:
		if last <= rand and rand < last + item.rarity:
			print("Get item: ", item.name)
			var remainder = player.add_item(item)
			if not multiplayer.has_multiplayer_peer() or player.is_multiplayer_authority():
				if remainder > 0:
					$/root/hud/notification.notify("You can't carry more than %d %s" % [item.max_quantity, item.name])
				else:
					$/root/hud/notification.notify("You got %d %s" % [item.quantity, item.name])
			break
		last += item.rarity
	quantity -= 1;
	if quantity <= 0:
		queue_free()
