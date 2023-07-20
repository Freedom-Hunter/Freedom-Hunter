extends Consumable
class_name Barrel


var scene = preload("res://data/scenes/items/barrel.tscn")


func _init(_name, _icon, _quantity):
	super(_name, _icon, _quantity, 5, 10)
	pass


func effect(player):
	var barrel = scene.instantiate()
	player.drop_item_on_floor(barrel)
	return true


func clone():
	return get_script().new(name, icon, quantity)
