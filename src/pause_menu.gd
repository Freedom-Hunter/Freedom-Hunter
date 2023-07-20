extends Popup

@onready var global = get_node("/root/global")


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


func _input(event):
	global._input(event)

