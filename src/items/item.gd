var name  # Item name
var icon  # Item icon, it would better be in 180px x 180px
var quantity  # Number of items you have
var rarity  # Percentage value (0-99)


func _init(_name, _icon, _quantity, _rarity):
	name = _name
	icon = _icon
	quantity = _quantity
	rarity = _rarity

func clone():
	return get_script().new(name, icon, quantity, rarity)