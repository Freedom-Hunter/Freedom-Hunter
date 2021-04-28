extends Consumable
class_name Whetstone


var sharp


func _init(_name, _icon, _quantity, _sharpening).(_name, _icon, _quantity, 20, 10):
	sharp = _sharpening


func effect(_player):
	if _player.equipment.weapon != null and not _player.equipment.weapon.is_sharpened():
		_player.equipment.weapon.sharpen(sharp)
		_player.animation_node.play("whetstone")
		return true
	return false


func clone():
	return get_script().new(name, icon, quantity, sharp)
