extends Control

func _ready():
	set_process_input(true)

func _input(event):
	if event.is_action_released("ui_cancel"):
		if not get_tree().is_paused():
			pause()
		else:
			unpause()
	if event.is_action_released("ui_fullscreen"):
		OS.set_window_fullscreen(not OS.is_window_fullscreen())

func pause():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_node("/root/game/game_menu").show()
	get_tree().set_pause(true)

func unpause():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_node("/root/game/game_menu").hide()
	get_tree().set_pause(false)

func _on_quit_pressed():
	get_tree().quit()

func _on_restart_pressed():
	get_tree().change_scene("res://scene/game.tscn")
	get_tree().set_pause(false)

func _on_return_pressed():
	unpause()

func _on_fullscreen_pressed():
	OS.set_window_fullscreen(not OS.is_window_fullscreen())
