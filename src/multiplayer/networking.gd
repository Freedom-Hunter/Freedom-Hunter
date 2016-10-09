extends Node

#Autoload

onready var global = get_node("/root/global")

var Lobby = preload("res://src/multiplayer/lobby.gd")

var multiplayer = false
var players = {}
var peer
var lobby

func init_lobby():
	lobby = Lobby.new()
	lobby.set_name("lobby")
	add_child(lobby)

func _init_multiplayer():
	multiplayer = true
	peer = NetworkedMultiplayerENet.new()
	set_pause_mode(PAUSE_MODE_PROCESS)

func server_start(port, username=null, host=null):
	_init_multiplayer()
	if host != null:
		lobby.register_server(host, port)
		yield(lobby.http, "request_completed")
		if username != null:
			lobby.register_player(username)
	peer.create_server(port)
	get_tree().set_network_peer(peer)
	global.start_game(username)
	players[1] = global.local_player
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")

func client_start(ip, port, username):
	_init_multiplayer()
	peer.create_client(ip, port)
	get_tree().set_network_peer(peer)
	get_tree().connect("connected_to_server", self, "_connected_to_server", [username])
	get_tree().connect("connection_failed", self, "_connection_failed", [ip, port])
	get_tree().connect("server_disconnected", self, "_server_disconnected")

func _player_disconnected(id):
	if id in players:
		global.remove_player(players[id].get_name())
		players.erase(id)

func _disconnect_signals():
	get_tree().disconnect("connected_to_server", self, "_connected_to_server")
	get_tree().disconnect("connection_failed", self, "_connection_failed")

func _connected_to_server(username): # client
	_disconnect_signals()
	var id = get_tree().get_network_unique_id()
	rpc("register_player", id, username)

func _connection_failed(ip, port):
	_disconnect_signals()
	stop()
	global.stop_game()
	printerr("Connection to %s:%s failed" % [ip, port])

func _server_disconnected():
	stop()
	global.stop_game()
	printerr("Server disconnected")

remote func register_player(id, username):
	# If I'm the server, let the new guy know about existing players
	if get_tree().is_network_server():
		if global.game.get_node("player_spawn").has_node(username):
			rpc_id(id, "_register_error", "Username is in use")
			return
		# Send the info of existing players
		players[id] = global.add_player(username)
		rpc_id(id, "_register_ok", id, username)
		for peer_id in players:
			if peer_id != id:
				rpc_id(id, "register_player", peer_id, players[peer_id].get_name())
	else:
		players[id] = global.add_player(username)

remote func _register_ok(id, username):
	global.start_game(username)
	players[id] = global.local_player

remote func _register_error(reason):
	print('Server refused connection: "%s"' % reason)
	global.stop_game()
	stop()

func stop():
	multiplayer = false
	peer = NetworkedMultiplayerENet.new()
	get_tree().set_network_peer(null)

func is_server():
	return multiplayer and get_tree().is_network_server()

func is_client_connected():
	if get_tree().is_network_server():
		return false
	return multiplayer and peer.get_connection_status() == NetworkedMultiplayerPeer.CONNECTION_CONNECTED

func get_players():
	return players.values()
