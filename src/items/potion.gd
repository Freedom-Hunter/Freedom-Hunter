extends "usable_item.gd"

var heal


func _init(_name, _icon, _quantity, _player, _heal).(_name, _icon, _quantity, 10, 50, _player):
	heal = _heal

func effect():
	if player.hp < player.hp_max:
		player.heal(heal)
		player.animation_node.play("drink")
		return true
	return false

func clone():
	return get_script().new(name, icon, quantity, player, heal)
