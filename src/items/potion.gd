extends "usable_item.gd"
class_name Potion


var heal: int


func _init(_name, _icon, _quantity, _heal).(_name, _icon, _quantity, 10, 50):
	heal = _heal


func effect(player: Player):
	if player.hp < player.hp_max:
		player.heal(heal)
		player.animation_node.play("drink")
		return true
	return false


func clone():
	return get_script().new(name, icon, quantity, heal)
