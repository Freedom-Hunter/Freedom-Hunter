extends "gathering.gd"

var Potion = preload("res://src/items/potion.gd")
var Firework = preload("res://src/items/firework.gd")
var Barrel = preload("res://src/items/barrel.gd")

var potion = Potion.new(null, preload("res://data/images/items/potion.png"), "Potion", 1, 25)
var firework = Firework.new(null, preload("res://data/images/items/firework.png"), "Firework", 1)
var barrel = Barrel.new(null, preload("res://data/images/items/barrel.png"), "Barrel", 1)

func _init().([barrel, firework, potion], rand_range(2,5)):
	pass
