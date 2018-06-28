extends "usable_item.gd"

var scene = preload("res://data/scenes/items/barrel.tscn")


func _init(_name, _icon, _quantity, _player).(_name, _icon, _quantity, 5, 10, _player):
	pass

func effect():
	var barrel = scene.instance()
	player.drop_item(barrel)
	return true

func clone():
	return get_script().new(name, icon, quantity, player)
