extends Consumable
class_name Whetstone


var sharp


func _init(_name, _icon, _quantity, _sharpening):
	super(_name, _icon, _quantity, 20, 10)
	sharp = _sharpening


func effect(_player: Player):
	if _player.equipment.weapon != null and not _player.equipment.weapon.is_sharpened():
		_player.equipment.weapon.sharpen(sharp)
		_player.consume_item_animation("whetstone")
		return true
	return false


func clone():
	return get_script().new(name, icon, quantity, sharp)
