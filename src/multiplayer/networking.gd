extends Node

#Autoload

onready var global = get_node("/root/global")

var Lobby = preload("res://src/multiplayer/lobby.gd")

var peer
var lobby
var players = {}
var unique_id = 1

signal start_game

func init_lobby():
	lobby = Lobby.new()
	lobby.set_name("lobby")
	add_child(lobby)
	print_stack()

func server_start(port, username=null, host=null):
	peer = NetworkedMultiplayerENet.new()
	peer.create_server(port)
	get_tree().set_network_peer(peer)
	unique_id = peer.get_unique_id()
	set_pause_mode(PAUSE_MODE_PROCESS)
	#if host != null:
	#	print("Announcing server")
	#	lobby.register_server(host, port)
	#	yield(lobby.http, "request_completed")
	#	if username != null:
	#		print("Announcing player")
	#		lobby.register_player(username)
	global.start_game(username)
	players[unique_id] = global.local_player
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("network_peer_connected", self, "_peer_connected")

func _player_disconnected(id):
	if id in players:
		print("Player %s (ID %d) disconnected" % [players[id].get_name(), id])
		global.remove_player(players[id].get_name())
		players.erase(id)

func _peer_connected(id):
	print("Peer ID %d connected" % id)

func client_start(ip, port, username):
	peer = NetworkedMultiplayerENet.new()
	peer.create_client(ip, port)
	get_tree().set_network_peer(peer)
	unique_id = peer.get_unique_id()
	set_pause_mode(PAUSE_MODE_PROCESS)
	get_tree().connect("connected_to_server", self, "_connected_to_server", [username])
	get_tree().connect("connection_failed", self, "_connection_failed", [ip, port])
	get_tree().connect("server_disconnected", self, "_server_disconnected")

func _disconnect_signals():
	get_tree().disconnect("connected_to_server", self, "_connected_to_server")
	get_tree().disconnect("connection_failed", self, "_connection_failed")

func _connected_to_server(username): # client
	_disconnect_signals()
	global.start_game(username)
	players[unique_id] = global.local_player
	print("Client %d connected to server" % unique_id)
	rpc("register_player", unique_id, username)

func _connection_failed(ip, port):
	_disconnect_signals()
	stop()

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
		players[id] = global.add_player(username, id)
		# Send the info of existing players
		for peer_id in players:
			if peer_id != id:
				rpc_id(id, "register_player", peer_id, players[peer_id].get_name())
				prints("send register_player", players[peer_id].get_name())
	else:
		players[id] = global.add_player(username, id)

remote func _register_error(reason):
	print('Server refused connection: "%s"' % reason)
	global.stop_game()
	stop()

func stop():
	peer = null
	get_tree().set_network_peer(null)
	unique_id = 1

func is_server():
	return get_tree().has_network_peer() and get_tree().is_network_server()

func is_client_connected():
	return peer == null or peer.get_connection_status() == NetworkedMultiplayerPeer.CONNECTION_CONNECTED

func get_players():
	return players.values()
