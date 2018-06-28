extends "usable_item.gd"

var sharp


func _init(_name, _icon, _quantity, _player, _sharpening).(_name, _icon, _quantity, 20, 10, _player):
	sharp = _sharpening

func effect():
	if player.equipment.weapon != null and not player.equipment.weapon.is_sharpened():
		player.equipment.weapon.sharpen(sharp)
		player.animation_node.play("whetstone")
		player.audio(preload("res://data/sounds/whetstone.wav"))
		return true
	return false

func clone():
	return get_script().new(name, icon, quantity, player, sharp)
