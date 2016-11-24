extends "item.gd"

var scene = preload("res://scene/items/firework.tscn")

func _init(p, i, n, q).(p, i, n, q, 20, true, 10):
	pass

func effect():
	var player_t = player.get_global_transform()
	var firework = scene.instance()
	firework.set_global_transform(player_t)
	player.get_parent().add_child(firework)

func clone():
	return get_script().new(player, icon, name, quantity)
