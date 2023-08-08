# SPDX-FileCopyrightText: 2023 Elia Argentieri
#
# SPDX-License-Identifier: GPL-3.0-or-later

class_name Collectible
extends "item.gd"


func _init(_name: String, _icon: Texture2D, _quantity: int, _rarity: int) \
.(_name, _icon, _quantity, _rarity):
	pass


func clone():
	return get_script().new(name, icon, quantity, rarity)

