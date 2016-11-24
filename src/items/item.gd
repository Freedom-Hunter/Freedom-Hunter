var player
var icon
var name
var quantity
var max_quantity
var usable
var rarity
var keep

func effect():
	return true

func use():
	if usable and quantity > 0:
		if effect():
			quantity -= 1

func _init(_player, _icon, _name, _quantity, _max_quantity, _usable, _rarity, _keep=false):
	player = _player
	icon = _icon
	name = _name
	quantity = _quantity
	max_quantity = _max_quantity
	usable = _usable
	rarity = _rarity
	keep = _keep

func clone():
	return get_script().new(player, icon, name, quantity, max_quantity, usable, rarity, keep)

func add(n):
	# returns how many items can't be added due to max_quantity limit
	var max_n = max_quantity - quantity
	if n <= max_n:
		quantity += n
		return 0
	quantity += max_n
	return n - max_n

func set_label_color(label):
	if quantity >= max_quantity:
		label.add_color_override("font_color", Color(1, 0, 0))
		label.add_color_override("font_color_shadow", Color(0, 0, 0, 0))
	else:
		label.add_color_override("font_color", Color(1, 1, 1))
		label.add_color_override("font_color_shadow", Color(0.2, 0.2, 0.2))
