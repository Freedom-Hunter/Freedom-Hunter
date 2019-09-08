extends "usable_item.gd"

var stamina


func _init(_name, _icon, _quantity, _player, _stamina).(_name, _icon, _quantity, 10, 50, _player):
	stamina = _stamina


func effect():
	if player.stamina_max < player.MAX_STAMINA and player.is_idle():
		player.stamina_max_increase(stamina)
		player.animation_node.play("eat")
		return true
	return false


func clone():
	return get_script().new(name, icon, quantity, player, stamina)
