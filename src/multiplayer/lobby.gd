extends Node

const BASE_URL = "https://elinvention.ovh"

var http
var external

var player_id = null
var server_id = null

func _ready():
	http = HTTPRequest.new()
	http.set_use_threads(true)
	http.set_name("HTTPRequest")
	add_child(http)

func servers_list(object, method):
	http.request(BASE_URL + "/fh/cmd.php?cmd=list_servers")
	http.connect("request_completed", object, method)

func register_player(_name, id=server_id):
	print("Register player")
	http.request(BASE_URL + "/fh/cmd.php?cmd=register_player&name=%s&server=%s&status=connected" % [_name, id])
	http.connect("request_completed", self, "_on_register_player_completed")

func _on_register_player_completed(result, response_code, headers, body):
	http.disconnect("request_completed", self, "_on_register_player_completed")
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		player_id = str2var(body.get_string_from_utf8())
		print("Player registered to lobby with ID: %s" % player_id)
	else:
		printerr("Can't register player to the multiplayer lobby")

func unregister_player():
	print("Unregister player")
	http.request(BASE_URL + "/fh/cmd.php?cmd=unregister_player&id=%s" % player_id)
	player_id = null

func register_server(host, port):
	print("Register server")
	http.request(BASE_URL + "/fh/cmd.php?cmd=register_server&hostname=%s&port=%s&max_players=10" % [host, port])
	http.connect("request_completed", self, "_on_register_server_completed")

func _on_register_server_completed(result, response_code, headers, body):
	http.disconnect("request_completed", self, "_on_register_server_completed")
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		server_id = str2var(body.get_string_from_utf8())
	else:
		printerr("Can't register server to the multiplayer lobby")

func unregister_server():
	print("Unregister server")
	http.request(BASE_URL + "/fh/cmd.php?cmd=unregister_server&id=%s" % server_id)
	server_id = null
