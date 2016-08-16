extends Node

export (int, FLAGS, "Fire", "Water", "Ice", "Thunder", "Dragon", \
"Poison", "Paralysis") var elements_type = 0

export var elements_effect = IntArray()

var elements = {}

func _ready():
	# It builds a dictionary with the name of the weapon's elements as key
	# and as a value taken from the power of the element
	var j = 0
	for i in range(global.ELEMENTS.size()):
		if int(pow(2, i)) & elements_type:
			elements[global.ELEMENTS[i]] = elements_effect[j]
			j += 1

