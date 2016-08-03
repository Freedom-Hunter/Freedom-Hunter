extends Control

func _ready():
	set_process_input(true)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()

func _on_singleplayer_pressed():
	global.start_game("Player")
	queue_free()

func _on_multiplayer_pressed():
	get_tree().change_scene("res://scene/multiplayer/config.tscn")
