extends Control

var touch_index = null
var drag = 0

onready var global = get_node("/root/global")
onready var hud = get_node("/root/game/hud")

func _ready():
	if OS.has_touchscreen_ui_hint():
		set_process_input(true)

func _input(event):
	if event is InputEventScreenTouch:
		if event.is_pressed() and get_rect().has_point(event.pos):
			touch_index = event.index
			drag = 0
		else:
			touch_index = null
	elif event is InputEventScreenDrag and event.index == touch_index:
		drag += event.relative_x
		if drag > 50:
			global.local_player.inventory.activate_prev()
			hud.update_items()
			drag = 0
		elif drag < -50:
			global.local_player.inventory.activate_next()
			hud.update_items()
			drag = 0
		accept_event()
