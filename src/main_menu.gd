extends Control

func _ready():
	set_process_input(true)

func _on_singleplayer_pressed():
	# ToDo: select characters
	print("Load game")
	get_tree().change_scene("res://scene/game.tscn")

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()