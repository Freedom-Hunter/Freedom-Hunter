# SPDX-FileCopyrightText: 2023 Elia Argentieri
#
# SPDX-License-Identifier: GPL-3.0-or-later

extends "gathering.gd"


var potion    = Potion.new("Potion",       preload("res://data/images/items/potion.png"),    1, 20)
var firework  = Firework.new("Firework",   preload("res://data/images/items/firework.png"),  1)
var barrel    = Barrel.new("Barrel",       preload("res://data/images/items/barrel.png"),    1)
var whetstone = Whetstone.new("Whetstone", preload("res://data/images/items/whetstone.png"), 1, 20)
var meat      = Meat.new("Meat",           preload("res://data/images/items/meat.png"),      1, 50)


func _init():
	super([barrel, firework, potion, meat], randf_range(2, 10))
	pass
