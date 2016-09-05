
extends Control

onready var analog = get_node("analog")
onready var stick = analog.get_node("stick")
onready var stick_rest_pos = stick.get_pos()
onready var buttons = get_node("buttons")

var touch_index = null
var direction = Vector2()
var intensity = Vector2()

var a_action = "player_attack_left"
var b_action = "player_attack_right"
var x_action = "player_jump"
var y_action = "player_use"

func _ready():
	var scale = OS.get_window_size().y / get_viewport_rect().size.y
	analog.set_scale(analog.get_scale() * scale)
	buttons.set_scale(buttons.get_scale() * scale)
	if OS.has_virtual_keyboard():
		show()
		InputMap.erase_action("player_attack_left")
		InputMap.add_action("player_attack_left")
		set_process_input(true)
	else:
		hide()
		set_process_input(false)

func _input(event):
	if event.type == InputEvent.SCREEN_TOUCH:
		if event.is_pressed() and analog.get_rect().has_point(event.pos):
			touch_index = event.index
			accept_event()
		elif event.index == touch_index:
			touch_index = null
			stick.set_pos(stick_rest_pos)
			direction = Vector2()
			accept_event()
	elif event.type == InputEvent.SCREEN_DRAG and event.index == touch_index:
		var pos = event.pos - analog.get_pos() - stick_rest_pos - stick.get_size() / 2
		direction = pos.normalized()
		intensity = pos.length()
		if intensity > 60:
			pos = direction * 60
			intensity = 60
		stick.set_pos(pos + stick_rest_pos)
		accept_event()

func send_action(action):
	var ev = InputEvent()
	ev.type = InputEvent.ACTION
	ev.set_as_action(action, true)
	get_tree().input_event(ev)

func _on_A_pressed():
	Input.action_press(a_action)

func _on_A_released():
	Input.action_release(a_action)

func _on_B_pressed():
	Input.action_press(b_action)

func _on_B_released():
	Input.action_release(b_action)

func _on_X_pressed():
	Input.action_press(x_action)

func _on_X_released():
	Input.action_release(x_action)

func _on_Y_pressed():
	Input.action_press(y_action)
	send_action(y_action)

func _on_Y_released():
	Input.action_release(y_action)
