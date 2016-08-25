var player
var icon
var name
var quantity
var max_quantity
var usable
var rarity

func effect():
	pass

func use():
	if usable and quantity > 0:
		quantity -= 1
		effect()

func init(pla, ico, nam, qua, usa, rar):
	player = pla
	icon = ico
	name = nam
	quantity = qua
	max_quantity = 10
	usable = usa
	rarity = rar

func clone(item):
	player = item.player
	icon = item.icon
	name = item.name
	quantity = item.quantity
	max_quantity = item.max_quantity
	usable = item.usable
	rarity = item.rarity
	return self

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
