
extends "item.gd"

var heal

func init(p, i, n, q, h):
	.init(p, i, n, q, 10, true, 50)
	heal = h

func effect():
	player.heal(heal)
	player.audio_node.play("potion_drink")
