extends "item.gd"

var scene = preload("res://data/scenes/items/barrel.tscn")

func _init(p, i, n, q).(p, i, n, q, 5, true, 5):
	pass

func effect():
	var drop = player.get_node("drop_item").get_global_transform()
	var barrel = scene.instance()
	barrel.set_global_transform(drop)
	player.get_parent().add_child(barrel)
	return true

func clone():
	return get_script().new(player, icon, name, quantity)
