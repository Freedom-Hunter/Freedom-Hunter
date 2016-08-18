extends "gathering.gd"

var Potion = preload("res://src/items/potion.gd")
var Firework = preload("res://src/items/firework.gd")
var Barrel = preload("res://src/items/barrel.gd")

var potion = Potion.new()
var firework = Firework.new()
var barrel = Barrel.new()

func _init():
	potion.init(self, preload("res://media/items/potion.png"), "Potion", 1, 25)
	firework.init(self, preload("res://media/items/firework.png"), "Firework", 1)
	barrel.init(self, preload("res://media/items/barrel.png"), "Barrel", 1)
	obtainable = [barrel, firework, potion]
	quantity = 3
	.init()
