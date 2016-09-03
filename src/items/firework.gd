extends "item.gd"

var scene = preload("res://scene/items/firework.tscn")

func init(p, i, n, q):
	.init(p, i, n, q, 20, true, 10)

func effect():
	var player_t = player.get_global_transform()
	var firework = scene.instance()
	firework.set_global_transform(player_t)
	player.get_parent().add_child(firework)
