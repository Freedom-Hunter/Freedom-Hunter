extends "usable_item.gd"

var heal


func _init(_name, _icon, _quantity, _player, _heal).(_name, _icon, _quantity, 10, 50, _player):
	heal = _heal

func effect():
	if player.hp < player.max_hp:
		player.heal(heal)
		player.audio(preload("res://data/sounds/potion_drink.wav"))
		return true
	return false

func clone():
	return get_script().new(name, icon, quantity, player, heal)
