extends Node

func _on_player_connected(player):
	print("%s connected" % player.get_name())
	get_node("player_spawn/" + networking.local_player + "/yaw/pitch/camera").make_current()
	get_node("hud").player_connected(player)

func _on_player_disconnected(player):
	print("%s disconnected" % player.get_name())
	get_node("hud").player_disconnected(player)
	get_node("player_spawn/" + player.get_name()).queue_free()

func _on_disconnected():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene("res://scene/main_menu.tscn")
