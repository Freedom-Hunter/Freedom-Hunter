extends "item.gd"


var player  # Owner of the item
var max_quantity


func _init(_name, _icon, _quantity, _max_quantity, _rarity, _player).(_name, _icon, _quantity, _rarity):
	player = _player
	max_quantity = _max_quantity


func clone():
	return get_script().new(name, icon, quantity, max_quantity, rarity, player)


func effect():
	return true


func use():
	if quantity > 0 and effect():
		quantity -= 1


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
