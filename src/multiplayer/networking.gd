extends Node

#Autoload

onready var global = get_node("/root/global")

var Server = preload("res://src/multiplayer/server.gd")
var Client = preload("res://src/multiplayer/client.gd")
var Lobby = preload("res://src/multiplayer/lobby.gd")

var peer
var lobby
var multiplayer = false

func _ready():
	lobby = Lobby.new()
	lobby.set_name("lobby")
	add_child(lobby)
	set_pause_mode(PAUSE_MODE_PROCESS)

func is_server():
	if multiplayer:
		return (peer extends Server)
	return false

func server_start(port, username=null, host=null):
	multiplayer = true
	if host != null:
		print("Announcing server")
		lobby.register_server(host, port)
		yield(lobby.http, "request_completed")
		if username != null:
			print("Announcing player")
			lobby.register_player(username)
	peer = Server.new()
	peer.global = global
	global.start_game(username)
	peer.start(port)
	set_process(true)
	return peer

func client_start(ip, port, username, server_id=null):
	multiplayer = true
	if server_id != null:
		print("Announcing player")
		lobby.register_player(username, server_id)
	peer = Client.new()
	peer.global = global
	global.start_game(username)
	peer.start(ip, port)
	set_process(true)
	return peer

func _process(delta):
	if multiplayer:
		peer.process(delta)

func stop():
	if peer != null:
		peer.stop()
	peer = null
	multiplayer = false
	set_process(false)

func get_players():
	if multiplayer:
		return peer.players.values()
	else:
		return []

func is_connected():
	if multiplayer:
		if peer extends Server:
			return true
		return peer.connected
	return false
