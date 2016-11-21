extends Node

export (int, -100, 100) var fire		= 0
export (int, -100, 100) var water		= 0
export (int, -100, 100) var ice			= 0
export (int, -100, 100) var thunder 	= 0
export (int, -100, 100) var dragon		= 0
export (int, -100, 100) var poison		= 0
export (int, -100, 100) var paralysis	= 0
export (int, -100, 100) var damage	= 0

var elements = {}

func _init():
	elements = {"fire": fire, "water": water, "ice": ice,
		"thunder": thunder, "dragon": dragon, "poison": poison,
		"paralysis": paralysis}

