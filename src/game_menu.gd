extends Control

func _ready():
	set_process_input(true)

func _on_quit_pressed():
	get_tree().quit()
	
func _input(event):
	if event.is_action_released("ui_cancel"):
		if not get_tree().is_paused():
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			get_node("/root/game/game_menu").show()
			get_tree().set_pause(true)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			get_node("/root/game/game_menu").hide()
			get_tree().set_pause(false)
	