extends Node

#Autoload

var server
var client
var multiplayer = false

onready var global = get_node("/root/global")

func _ready():
	set_pause_mode(PAUSE_MODE_PROCESS)

func server_start(port, username=null):
	server = preload("res://src/multiplayer/server.gd").new()
	server.global = global
	var game = global.start_game(username)
	server.start(game, port)
	multiplayer = true
	set_process(true)
	return server

func client_start(ip, port, username=null):
	client = preload("res://src/multiplayer/client.gd").new()
	client.global = global
	var game = global.start_game(username)
	client.start(game, ip, port)
	multiplayer = true
	set_process(true)
	return client

func _process(delta):
	if server != null:
		server.process(delta)
	elif client != null:
		client.process(delta)
	else:
		set_process(false)

func server_stop():
	server.stop()
	server = null
	multiplayer = false
	set_process(false)

func client_stop():
	client.stop()
	client = null
	multiplayer = false
	set_process(false)

func _exit_tree():
	if server != null:
		server_stop()
	if client != null:
		client_stop()

func get_players():
	if server != null:
		return server.players.values()
	elif client != null:
		return client.players.values()
	else:
		return []

func stop():
	if server != null:
		server_stop()
	if client != null:
		client_stop()
