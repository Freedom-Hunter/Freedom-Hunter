class_name NetworkingAutoload
extends Node

#Autoload

@onready var global: GlobalAutoload = get_node("/root/global")


var peer: ENetMultiplayerPeer
var lobby: Lobby
var players := {}
var unique_id := 1


func init_lobby() -> void:
	lobby = Lobby.new()
	lobby.set_name("lobby")
	add_child(lobby)


func server_start(port: int, username=null, host=null) -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_server(port)
	multiplayer.multiplayer_peer = peer
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
	multiplayer.peer_disconnected.connect(_on_network_peer_disconnected)
	multiplayer.peer_connected.connect(_on_network_peer_connected)


func client_start(ip: String, port: int, username: String) -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, port)
	multiplayer.multiplayer_peer = peer
	unique_id = peer.get_unique_id()
	set_process_mode(PROCESS_MODE_ALWAYS)
	multiplayer.connected_to_server.connect(_connected_to_server.bind(username))
	multiplayer.connection_failed.connect(_connection_failed.bind(ip, port))
	multiplayer.server_disconnected.connect(_server_disconnected)
	multiplayer.peer_connected.connect(_on_network_peer_connected)
	multiplayer.peer_disconnected.connect(_on_network_peer_disconnected)


func _connected_to_server(username: String) -> void: # client
	global.start_game(username)
	players[unique_id] = global.local_player
	print("Client %d connected to server" % unique_id)
	rpc("register_player", unique_id, username, null)


func _connection_failed(_ip, _port) -> void:
	stop()


func _server_disconnected() -> void:
	stop_and_report_error("Server disconnected.")


func _on_network_peer_connected(id) -> void:
	print("Peer ID %d connected" % id)


func _on_network_peer_disconnected(id) -> void:
	if id in players:
		print("Player %s (peer ID %d) disconnected" % [players[id].name, id])
		global.remove_player(players[id].name)
		players.erase(id)
	else:
		print("Peer ID %d disconnected" % id)


@rpc("any_peer") func register_player(id, username, transform) -> void:
	# If I'm the server, let the new guy know about existing players
	if multiplayer.is_server():
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


@rpc("any_peer") func _register_error(reason) -> void:
	stop_and_report_error('Server refused connection: "%s"' % reason)


func stop() -> void:
	if peer != null:
		peer.close()
		peer = null
	players = {}
	multiplayer.multiplayer_peer = null
	unique_id = 1


func stop_and_report_error(message) -> void:
	global.stop_game()
	# Wait for change_scene(main_menu) to complete (called by global.stop_game)
	await get_tree().tree_changed
	#await get_tree().idle_frame
	# Now main_menu is really ready
	$"/root/main_menu/multiplayer".show()
	$"/root/main_menu/multiplayer".report_error(message)


func is_server():
	return multiplayer.has_multiplayer_peer() and multiplayer.is_server()


func is_client_connected() -> bool:
	return peer == null or peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED


func get_players() -> Array:
	return players.values()
