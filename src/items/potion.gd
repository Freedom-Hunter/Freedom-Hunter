
extends "item.gd"

var heal

func _init(p, i, n, q, h).(p, i, n, q, 10, true, 50):
	heal = h

func effect():
	if player.hp < player.max_hp:
		player.heal(heal)
		player.audio_node.play("potion_drink")
		return true
	return false

func clone():
	return get_script().new(player, icon, name, quantity, heal)
