extends Control

func _ready():
	print("Waiting for players...")
	networking.connect("player_connected", self, "_on_player_connected")
	networking.connect("player_disconnected", self, "_on_player_disconnected")
	networking.connect("game_begins", self, "_on_game_begins")
	networking.connect("server_down", self, "_on_server_down")
	if not networking.server:
		get_node("play").set_disabled(true)
	networking.set_process(true)
	_on_player_connected(networking.local_player)

func _on_player_connected(player_name):
	var label = Label.new()
	label.set_text(player_name)
	get_node("list").add_child(label)

func _on_player_disconnected(player_name):
	for child in get_node("list").get_children():
		if child.get_text() == player_name:
			child.queue_free()
			break

func _on_play_pressed():
	if networking.players.size() > 0:
		networking.server_begin_game()
		global.start_game(networking.local_player, networking.players)
		queue_free()

func _on_game_begins():
	global.start_game(networking.local_player, networking.players)
	queue_free()

func _on_server_down():
	get_tree().change_scene("res://scene/multiplayer/config.tscn")
