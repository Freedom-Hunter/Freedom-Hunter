var player
var icon
var name
var quantity
var usable

func effect():
	pass

func use():
	if usable and quantity > 0:
		quantity -= 1
		effect()

func init(p, i, n, q, u):
	player = p
	icon = i
	name = n
	quantity = q
	usable = u
