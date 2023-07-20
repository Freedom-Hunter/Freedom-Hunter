extends Node

#Autoload

@onready var global = get_node("/root/global")

var Lobby = preload("res://src/multiplayer/lobby.gd")

var peer
var lobby
var players = {}
var unique_id = 1


func init_lobby():
	lobby = Lobby.new()
	lobby.set_name("lobby")
	add_child(lobby)


func server_start(port, username=null, host=null):
	peer = ENetMultiplayerPeer.new()
	peer.create_server(port)
	get_tree().set_multiplayer_peer(peer)
	unique_id = peer.get_unique_id()
	set_process_mode(PROCESS_MODE_ALWAYS)
	#if host != null:
	#	print("Announcing server")
	#	lobby.register_server(host, port)
	#	yield(lobby.http, "request_completed")
	#	if username != null:
	#		print("Announcing player")
	#		lobby.register_player(username)
	global.start_game(username)
	players[unique_id] = global.local_player
	get_tree().connect("peer_disconnected", Callable(self, "_on_network_peer_disconnected"))
	get_tree().connect("peer_connected", Callable(self, "_on_network_peer_connected"))


func client_start(ip, port, username):
	peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, port)
	get_tree().set_multiplayer_peer(peer)
	unique_id = peer.get_unique_id()
	set_process_mode(PROCESS_MODE_ALWAYS)
	get_tree().connect("connected_to_server", Callable(self, "_connected_to_server").bind(username))
	get_tree().connect("connection_failed", Callable(self, "_connection_failed").bind(ip, port))
	get_tree().connect("server_disconnected", Callable(self, "_server_disconnected"))
	get_tree().connect("peer_connected", Callable(self, "_on_network_peer_connected"))
	get_tree().connect("peer_disconnected", Callable(self, "_on_network_peer_disconnected"))


func _connected_to_server(username): # client
	global.start_game(username)
	players[unique_id] = global.local_player
	print("Client %d connected to server" % unique_id)
	rpc("register_player", unique_id, username, null)


func _connection_failed(_ip, _port):
	stop()


func _server_disconnected():
	stop_and_report_error("Server disconnected.")


func _on_network_peer_connected(id):
	print("Peer ID %d connected" % id)


func _on_network_peer_disconnected(id):
	if id in players:
		print("Player %s (peer ID %d) disconnected" % [players[id].name, id])
		global.remove_player(players[id].name)
		players.erase(id)
	else:
		print("Peer ID %d disconnected" % id)


@rpc("any_peer") func register_player(id, username, transform):
	# If I'm the server, let the new guy know about existing players
	if get_tree().is_server():
		if global.game.find_child("player_spawn").has_node(username):
			rpc_id(id, "_register_error", "Username is in use")
			peer.disconnect_peer(id)
			print('Peer ID %d username "%s" already in use' % [id, username])
			return
		for peer_id in players:
			# Send the info of existing players
			var player = players[peer_id]
			rpc_id(id, "register_player", peer_id, player.name, player.transform)
			print("Sending info about %s(%d) to client %d" % [player.name, peer_id, id])
			# Inform already connected clients about the new arrival
			rpc_id(peer_id, "register_player", id, username, transform)
		players[id] = global.add_player(username, id, transform)
	else:
		players[id] = global.add_player(username, id, transform)


@rpc("any_peer") func _register_error(reason):
	stop_and_report_error('Server refused connection: "%s"' % reason)


func stop():
	if peer != null:
		peer.close_connection()
		peer = null
	players = {}
	#get_tree().set_multiplayer_peer(null)  # FIXME
	unique_id = 1


func stop_and_report_error(message):
	global.stop_game()
	# Wait for change_scene(main_menu) to complete (called by global.stop_game)
	await get_tree().tree_changed
	await get_tree().idle_frame
	# Now main_menu is really ready
	$"/root/main_menu/multiplayer".show()
	$"/root/main_menu/multiplayer".report_error(message)


func is_server():
	return get_tree().has_multiplayer_peer() and get_tree().is_server()


func is_client_connected():
	return peer == null or peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED


func get_players():
	return players.values()
