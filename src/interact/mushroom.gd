extends "gathering.gd"

var Potion = preload("res://src/items/potion.gd")
var Firework = preload("res://src/items/firework.gd")
var Barrel = preload("res://src/items/barrel.gd")
var Meat = preload("res://src/items/meat.gd")

var potion = Potion.new(null, preload("res://media/items/potion.png"), "Potion", 1, 25)
var firework = Firework.new(null, preload("res://media/items/firework.png"), "Firework", 1)
var barrel = Barrel.new(null, preload("res://media/items/barrel.png"), "Barrel", 1)
var meat = Meat.new(null, preload("res://media/items/meat.png"), "Meat", 1, 50)

func _init().([barrel, firework, potion, meat], rand_range(2, 10)):
	pass
