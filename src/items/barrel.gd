extends "item.gd"

var scene = preload("res://scene/items/barrel.tscn")

func init(p, i, n, q):
	.init(p, i, n, q, 5, true, 5)

func effect():
	var drop = player.get_node("drop_item").get_global_transform()
	var barrel = scene.instance()
	barrel.set_global_transform(drop)
	player.get_parent().add_child(barrel)
