var player
var icon
var name
var quantity
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
	usable = usa
	rarity = rar
