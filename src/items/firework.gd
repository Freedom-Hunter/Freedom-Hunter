extends "usable_item.gd"

var scene = preload("res://data/scenes/items/firework.tscn")


func _init(_name, _icon, _quantity).(_name, _icon, _quantity, 10, 50):
	pass


func effect(_player):
	var firework = scene.instance()
	_player.drop_item_on_floor(firework)
	firework.get_node("animation").play("firework")
	return true


func clone():
	return get_script().new(name, icon, quantity)
