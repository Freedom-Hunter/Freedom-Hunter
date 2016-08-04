extends Node

#Autoload

var multiplayer = false
var server = false
onready var udp = PacketPeerUDP.new()
var clients = {}
var players = []
var local_player

signal player_connected
signal player_disconnected
signal game_begins
signal server_down

#Client to Server
const CMD_CS_CONNECT = 0
const CMD_CS_MOVE = 1
const CMD_CS_DISCONNECT = 100

#Server to Client
const CMD_SC_GAME_BEGIN = 101
const CMD_SC_CLIENT_CONNECTED = 102
const CMD_SC_PLAYERS_LIST = 103
const CMD_SC_CLIENT_DISCONNECTED = 110
const CMD_SC_MOVE = 111
const CMD_SC_DOWN = 200

func new_packet(command, args=null):
	var pckt = {'command': command}
	if args != null:
		pckt['args'] = args
	return pckt

func server_start(port, username):
	multiplayer = true
	server = true
	udp.listen(port)
	players = [username]
	local_player = username

func client_start(ip, port, username):
	multiplayer = true
	server = false
	udp.listen(0)
	udp.set_send_address(ip, port)
	udp.put_var(new_packet(CMD_CS_CONNECT, username))
	players = [username]
	local_player = username

func server_begin_game():
	for client in clients.values():
		udp.set_send_address(client.ip, client.port)
		udp.put_var(new_packet(CMD_SC_GAME_BEGIN, players))

func server_broadcast(pckt, except=null):
	for player in clients.keys():
		if player != except:
			var client = clients[player]
			udp.set_send_address(client.ip, client.port)
			udp.put_var(pckt)

func server_send_to_player(pckt, player):
	udp.set_send_address(clients[player].ip, clients[player].port)
	udp.put_var(pckt)

func process_client(pckt, delta):
	if pckt.command == CMD_SC_MOVE:
		get_node("/root/game/player_spawn/" + pckt.args.player).set_global_transform(pckt.args.transform)
	elif pckt.command == CMD_SC_GAME_BEGIN:
		emit_signal("game_begins")
	elif pckt.command == CMD_SC_CLIENT_CONNECTED:
		players.append(pckt.args)
		emit_signal("player_connected", pckt.args)
	elif pckt.command == CMD_SC_PLAYERS_LIST:
		for player in pckt.args:
			if not player in players:
				emit_signal("player_connected", player)
				players.append(player)
		for player in players:
			if not player in pckt.args:
				emit_signal("player_disconnected", player)
				players.erase(player)
	elif pckt.command == CMD_SC_CLIENT_DISCONNECTED:
		players.erase(pckt.args)
		emit_signal("player_connected", pckt.args)
	elif pckt.command == CMD_SC_DOWN:
		set_process(false)
		udp.close()
		emit_signal("server_down")
		print("Server shutdown!")

func process_server(pckt, delta):
	if pckt.command == CMD_CS_CONNECT:
		var player = pckt.args
		players.append(player)
		clients[player] = {'ip': udp.get_packet_ip(), 'port': udp.get_packet_port()}
		server_broadcast(new_packet(CMD_SC_CLIENT_CONNECTED, player), player)
		server_send_to_player(new_packet(CMD_SC_PLAYERS_LIST, players), player)
		emit_signal("player_connected", player)
	elif pckt.command == CMD_CS_MOVE:
		server_broadcast(new_packet(CMD_SC_MOVE, pckt.args), pckt.args.player)
		get_node("/root/game/player_spawn/" + pckt.args.player).set_global_transform(pckt.args.transform)
	elif pckt.command == CMD_CS_DISCONNECT:
		var player = pckt.args
		players.erase(player)
		clients.erase(player)
		emit_signal("player_disconnected", player)

func _process(delta):
	if udp.get_available_packet_count() > 0:
		var pckt = udp.get_var()
		if typeof(pckt) == TYPE_DICTIONARY:
			if server:
				process_server(pckt, delta)
			else:
				process_client(pckt, delta)
		else:
			print("Unknown Variant received!")

func _exit_tree():
	if server and players.size() > 1:
		print("Sending shutdown command to clients")
		server_broadcast(new_packet(CMD_SC_DOWN))
	else:
		print("Sending disconnect command to server")
		udp.put_var(new_packet(CMD_CS_DISCONNECT, local_player))
