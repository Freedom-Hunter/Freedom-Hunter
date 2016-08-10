extends Node

func _on_disconnected():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene("res://scene/main_menu.tscn")
