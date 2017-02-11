extends "usable_item.gd"

var scene = preload("res://data/scenes/items/barrel.tscn")


func _init(_name, _icon, _quantity, _player).(_name, _icon, _quantity, 5, 10, _player):
	pass

func effect():
	var drop = player.get_node("drop_item").get_global_transform()
	var barrel = scene.instance()
	barrel.set_global_transform(drop)
	player.get_parent().add_child(barrel)
	return true

func clone():
	return get_script().new(name, icon, quantity, player)
