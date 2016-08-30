
extends Control

onready var stick = get_node("stick")
onready var stick_rest_pos = stick.get_pos()

var touch_index = null
var direction = Vector2()

func _ready():
	var scale = OS.get_window_size().y / get_viewport_rect().size.y
	set_scale(get_scale() * scale)
	if OS.has_virtual_keyboard():
		show()
		set_process_input(true)
	else:
		hide()
		set_process_input(false)

func _input(event):
	if event.type == InputEvent.SCREEN_TOUCH:
		if event.is_pressed() and get_rect().has_point(event.pos):
			touch_index = event.index
		elif event.index == touch_index:
			touch_index = null
			stick.set_pos(stick_rest_pos)
			direction = Vector2()
		accept_event()
	if event.type == InputEvent.SCREEN_DRAG and event.index == touch_index:
		var pos = event.pos - get_pos() - stick_rest_pos
		direction = pos.normalized()
		if pos.length() > 40:
			pos = direction * 40
		stick.set_pos(pos + stick_rest_pos)
		accept_event()
