extends Control

onready var global = get_node("/root/global")

func _input(event):
	if event.is_action_pressed("ui_cancel") and $mode.is_visible():
		global.exit_clean()

func _on_singleplayer_pressed():
	global.start_game("Player")
	queue_free()

func _on_multiplayer_pressed():
	$mode.hide()
	$multiplayer.show()
