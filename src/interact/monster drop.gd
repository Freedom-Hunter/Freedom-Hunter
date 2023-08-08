# SPDX-FileCopyrightText: 2023 Elia Argentieri
#
# SPDX-License-Identifier: GPL-3.0-or-later

extends "gathering.gd"


var potion = Potion.new("Potion", preload("res://data/images/items/potion.png"), 1, 25)
var firework = Firework.new("Firework", preload("res://data/images/items/firework.png"), 1)
var barrel = Barrel.new("Barrel", preload("res://data/images/items/barrel.png"), 1)


func _init():
	super([barrel, firework, potion], randf_range(2,5))
	pass


func die():  # prevent errors in multiplayer
	pass
