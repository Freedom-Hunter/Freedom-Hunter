extends Node

#Autoload

var Server = preload("res://src/multiplayer/server.gd")
var Client = preload("res://src/multiplayer/client.gd")
var peer
var multiplayer = false

onready var global = get_node("/root/global")

func _ready():
	set_pause_mode(PAUSE_MODE_PROCESS)

func server_start(port, username=null):
	peer = Server.new()
	peer.global = global
	var game = global.start_game(username)
	peer.start(game, port)
	multiplayer = true
	set_process(true)
	return peer

func client_start(ip, port, username=null):
	peer = Client.new()
	peer.global = global
	var game = global.start_game(username)
	peer.start(game, ip, port)
	multiplayer = true
	set_process(true)
	return peer

func _process(delta):
	if multiplayer:
		peer.process(delta)

func stop():
	peer.stop()
	peer = null
	multiplayer = false
	set_process(false)

func _exit_tree():
	if multiplayer:
		stop()

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
