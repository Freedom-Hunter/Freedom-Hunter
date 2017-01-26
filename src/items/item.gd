var icon  # Tutti
var name  # Tutti
var rarity  # Tutti
var quantity  # Tutti

func _init(_icon, _name, _rarity, _quantity):
	icon = _icon
	name = _name
	rarity = _rarity
	quantity = _quantity

func clone():
	return get_script().new(icon, name, rarity, quantity)