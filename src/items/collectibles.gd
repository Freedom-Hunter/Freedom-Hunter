class_name Collectible
extends "item.gd"


func _init(_name: String, _icon: Texture, _quantity: int, _rarity: int) \
.(_name, _icon, _quantity, _rarity):
	pass


func clone():
	return get_script().new(name, icon, quantity, rarity)

