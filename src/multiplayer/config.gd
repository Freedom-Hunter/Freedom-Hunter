
extends Control

func _ready():
	global.packet = PacketPeerUDP.new()
	set_process_input(true)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		global.packet.close()
		get_tree().change_scene("res://scene/main_menu.tscn")

func _on_start_pressed():
	# Server
	var port = get_node("server/input/port").get_text()
	if port.is_valid_integer():
		print("Listen on port ", port)
		global.packet.listen(int(port))
		global.multiplayer = true
		global.server = true
		get_tree().change_scene("res://scene/multiplayer/waiting.tscn")
	else:
		print("La porta %s non è valida!" % port)

func _on_connect_pressed():
	# Client
	var port = get_node("client/input/port").get_text()
	var ip = get_node("client/input/ip").get_text()
	var username = get_node("client/input/username").get_text()

	if ip.is_valid_ip_address() and port.is_valid_integer() and username.length() > 0:
		global.packet.listen(0)
		global.packet.set_send_address(ip, int(port))
		global.packet.put_var(username)
		while global.packet.get_available_packet_count() == 0:
			OS.delay_msec(100)
		var players = global.packet.get_var()
		players.erase(username)
		global.multiplayer = true
		global.start_game(username, players)
		queue_free()
