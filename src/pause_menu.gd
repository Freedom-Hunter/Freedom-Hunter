extends Window

@onready var global: GlobalAutoload = get_node("/root/global")


func _on_quit_pressed():
	global.exit_clean()


func _on_return_pressed():
	global.unpause()


func _on_fullscreen_pressed():
	global.toggle_fullscreen()


func _on_main_menu_pressed():
	global.stop_game()


func _on_popup_hide():
	global.unpause()


func _input(event: InputEvent):
	global._input(event)


func _notification(what: int):
	match what:
		NOTIFICATION_WM_SIZE_CHANGED:
			print("new size: ", get_window().size)
		NOTIFICATION_APPLICATION_PAUSED:
			print("paused")
			#popup_centered()
		NOTIFICATION_APPLICATION_RESUMED:
			print("resumed")
			#hide()
		NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			print("focus out")
			#global.pause()

