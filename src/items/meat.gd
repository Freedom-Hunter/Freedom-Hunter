extends "usable_item.gd"

var stamina


func _init(_name, _icon, _quantity, _player, _stamina).(_name, _icon, _quantity, 10, 50, _player):
	stamina = _stamina

func effect():
	if player.max_stamina < player.MAX_STAMINA:
		player.increase_max_stamina(stamina)
		player.audio(preload("res://data/sounds/eat.wav"))
		return true
	return false

func clone():
	return get_script().new(name, icon, quantity, player, stamina)