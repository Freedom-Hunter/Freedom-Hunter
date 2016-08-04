extends Node

func begin_multiplayer():
	networking.connect("player_connected", self, "_on_player_connected")
	networking.connect("player_disconnected", self, "_on_player_disconnected")
	networking.connect("server_down", self, "_on_server_down")

func _on_player_connected(player_name):
	print("%s connected" % player_name)
	global.add_player(self, player_name, false, Vector3())
	get_node("player_spawn/" + networking.local_player + "/yaw/pitch/camera").make_current()

func _on_player_disconnected(player_name):
	print("%s disconnected" % player_name)
	for player in get_node("player_spawn").get_children():
		if player.get_name() == player_name:
			get_node("player_spawn").remove_child(player)
			break

func _on_server_down():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene("res://scene/multiplayer/config.tscn")
