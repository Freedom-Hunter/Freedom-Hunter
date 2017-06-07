
extends Control

onready var stick_rest_pos = $"analog/stick".get_position()

var touch_index = null
var direction = Vector2()
var intensity = 0

var a_action = "player_attack_left"
var b_action = "player_attack_right"
var x_action = "player_jump"
var y_action = "player_use"

func _ready():
	var scale = OS.get_window_size().y / get_viewport_rect().size.y
	$"analog".rect_scale *= scale
	$"buttons".rect_scale *= scale
	if OS.has_virtual_keyboard():
		show()
		InputMap.erase_action("player_attack_left")
		InputMap.add_action("player_attack_left")
		set_process_input(true)
	else:
		hide()

func _input(event):
	if event is InputEventScreenTouch:
		if event.is_pressed() and $"analog".get_rect().has_point(event.pos):
			touch_index = event.index
			accept_event()
		elif event.index == touch_index:
			touch_index = null
			$"analog/stick".set_position(stick_rest_pos)
			direction = Vector2()
			accept_event()
	elif event is InputEventScreenDrag and event.index == touch_index:
		var pos = event.pos - $"analog".get_position() - stick_rest_pos - $"analog/stick".get_size() / 2
		direction = pos.normalized()
		intensity = pos.length() / 60
		if intensity > 1:
			pos = direction
			intensity = 1
		$"analog/stick".set_position(pos + stick_rest_pos)
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
