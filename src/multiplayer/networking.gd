extends Node

#Autoload

const LOBBY_HOST = "elinvention.ovh"

onready var global = get_node("/root/global")

var Server = preload("res://src/multiplayer/server.gd")
var Client = preload("res://src/multiplayer/client.gd")

var peer
var multiplayer = false
var lobby_player_id = null
var lobby_server_id = null

func _ready():
	set_pause_mode(PAUSE_MODE_PROCESS)

func is_server():
	if multiplayer:
		return (peer extends Server)
	return false

func server_start(port, username=null, announce=false):
	multiplayer = true
	if announce:
		print("Announcing server")
		lobby_register_server(external_address().ip, port)
		if username != null:
			lobby_register_player(username, lobby_server_id)
	peer = Server.new()
	peer.global = global
	var game = global.start_game(username)
	peer.start(game, port)
	set_process(true)
	return peer

func client_start(ip, port, username, server_id=null):
	multiplayer = true
	if server_id != null:
		print("Announcing player")
		lobby_register_player(username, server_id)
	peer = Client.new()
	peer.global = global
	var game = global.start_game(username)
	peer.start(game, ip, port)
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
	lobby_unregister_player()
	lobby_unregister_server()

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

func external_address():
	return https_get(LOBBY_HOST, "/fh/ip.php")

func lobby_servers_list():
	return https_get(LOBBY_HOST, "/fh/cmd.php?cmd=list_servers")

func lobby_register_player(name, server_id):
	lobby_player_id = https_get(LOBBY_HOST, "/fh/cmd.php?cmd=register_player&name=%s&server=%s&status=connected" % [name, server_id])

func lobby_unregister_player():
	if lobby_player_id != null:
		https_get(LOBBY_HOST, "/fh/cmd.php?cmd=unregister_player&id=%s" % lobby_player_id)
		lobby_player_id = null

func lobby_register_server(host, port):
	lobby_server_id = https_get(LOBBY_HOST, "/fh/cmd.php?cmd=register_server&hostname=%s&port=%s&max_players=10" % [host, port])

func lobby_unregister_server():
	if lobby_server_id != null:
		https_get(LOBBY_HOST, "/fh/cmd.php?cmd=unregister_server&id=%s" % lobby_server_id)
		lobby_server_id = null

func https_get(host, query):
	var err = 0
	var http = HTTPClient.new() # Create the Client
	http.set_blocking_mode(true)

	var err = http.connect(host, 443, true, true) # Connect to host/port
	if err != OK:  # Make sure connection was OK
		return false

	# Wait until resolved and connected
	while http.get_status() == HTTPClient.STATUS_CONNECTING or http.get_status() == HTTPClient.STATUS_RESOLVING:
		http.poll()
		print("Connecting..")
		OS.delay_msec(10)

	if http.get_status() != HTTPClient.STATUS_CONNECTED: # Could not connect
		return false

	# Some headers

	var headers=[
		"User-Agent: Pirulo/1.0 (Godot)",
		"Accept: */*"
	]

	err = http.request(HTTPClient.METHOD_GET, query, headers) # Request a page from the site (this one was chunked..)
	if err != OK: # Make sure all is OK
		return false

	while http.get_status() == HTTPClient.STATUS_REQUESTING:
		# Keep polling until the request is going on
		http.poll()
		print("Requesting..")
		OS.delay_msec(10)


	if http.get_status() != HTTPClient.STATUS_BODY and http.get_status() != HTTPClient.STATUS_CONNECTED:
		# Make sure request finished well.
		return false

	if not http.has_response():
		return false

	if http.get_response_code() != 200:
		return false

	if not http.is_response_chunked():
		# Or just plain Content-Length
		var bl = http.get_response_body_length()

	# This method works for both anyway
	var rb = RawArray() # Array that will hold the data
	while http.get_status() == HTTPClient.STATUS_BODY:
		# While there is body left to be read
		http.poll()
		var chunk = http.read_response_body_chunk() # Get a chunk
		if chunk.size() == 0:
			# Got nothing, wait for buffers to fill a bit
			OS.delay_msec(10)
		else:
			rb = rb + chunk # Append to read buffer

	var text = rb.get_string_from_ascii()
	return str2var(text)
