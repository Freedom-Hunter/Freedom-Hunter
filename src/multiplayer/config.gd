
extends Control

func _ready():
	set_process_input(true)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		networking.close()
		get_tree().change_scene("res://scene/main_menu.tscn")

func _on_start_pressed():
	# Server
	var port = get_node("server/input/port").get_text()
	var username = get_node("server/input/username").get_text().strip_edges()
	if port.is_valid_integer() and username.length() > 0:
		print("Listen on port ", port)
		networking.server_start(int(port), username)
		global.start_game(username)
		queue_free()
	else:
		print("La porta %s non è valida!" % port)

func _on_connect_pressed():
	# Client
	var port = get_node("client/input/port").get_text()
	var host = get_node("client/input/host").get_text()
	var username = get_node("client/input/username").get_text().strip_edges()

	if port.is_valid_integer() and username.length() > 0:
		networking.client_start(host, int(port), username)
		global.start_game(username)
		queue_free()
