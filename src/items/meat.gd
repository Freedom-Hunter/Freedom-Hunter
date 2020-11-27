extends "usable_item.gd"
class_name Meat


var stamina


func _init(_name, _icon, _quantity, _stamina).(_name, _icon, _quantity, 10, 50):
	stamina = _stamina


func effect(_player):
	if _player.stamina_max < _player.MAX_STAMINA and _player.is_idle():
		_player.stamina_max_increase(stamina)
		_player.animation_node.play("eat")
		return true
	return false


func clone():
	return get_script().new(name, icon, quantity, stamina)
