class_name Firework
extends Consumable


var scene = preload("res://data/scenes/items/firework.tscn")


func _init(_name, _icon, _quantity):
	super(_name, _icon, _quantity, 10, 50)
	pass


func effect(_player):
	var firework = scene.instantiate()
	_player.drop_item_on_floor(firework)
	firework.launch()
	return true


func clone():
	return get_script().new(name, icon, quantity)
