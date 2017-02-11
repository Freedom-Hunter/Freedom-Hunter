extends "gathering.gd"

var Potion = preload("res://src/items/potion.gd")
var Firework = preload("res://src/items/firework.gd")
var Barrel = preload("res://src/items/barrel.gd")
var Whetstone = preload("res://src/items/whetstone.gd")
var Meat = preload("res://src/items/meat.gd")



var potion    = Potion.new("Potion",       preload("res://data/images/items/potion.png"),    1, null, 20)
var firework  = Firework.new("Firework",   preload("res://data/images/items/firework.png"),  1, null)
var barrel    = Barrel.new("Barrel",       preload("res://data/images/items/barrel.png"),    1, null)
var whetstone = Whetstone.new("Whetstone", preload("res://data/images/items/whetstone.png"), 1, null, 20)
var meat      = Meat.new("Meat",           preload("res://data/images/items/meat.png"),      1, null, 50)

func _init().([barrel, firework, potion, meat], rand_range(2, 10)):
	pass
