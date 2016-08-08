extends Node

#Autoload

var Player = preload("res://src/entities/player.gd")

onready var udp = PacketPeerUDP.new()

var multiplayer = false
var server = false
var clients = {}
var players = {}

var spawn_node
var game_node

signal player_connected
signal player_disconnected
signal disconnected

#Client to Server
const CMD_CS_CONNECT = 0
const CMD_CS_MOVE = 1
const CMD_CS_DAMAGE = 2
const CMD_CS_ATTACK = 3
const CMD_CS_DIE = 4
const CMD_CS_USE = 5
const CMD_CS_PING = 50
const CMD_CS_PONG = 51
const CMD_CS_DISCONNECT = 99

#Server to Client
const CMD_SC_PLAYER_CONNECTED = 100
const CMD_SC_CONNECT_ACCEPT = 101
const CMD_SC_USERNAME_IN_USE = 102
const CMD_SC_MAX_PLAYERS = 103
const CMD_SC_PLAYER_DISCONNECTED = 110
const CMD_SC_MOVE = 111
const CMD_SC_DAMAGE = 112
const CMD_SC_ATTACK = 113
const CMD_SC_DIE = 114
const CMD_SC_USE = 115
const CMD_SC_PING = 150
const CMD_SC_PONG = 151
const CMD_SC_DOWN = 200

const SERVER_PING_TIMEOUT = 3
const CLIENT_PING_TIMEOUT = 1
const PING_RETRY = 3

var client_connected = false
var client_ping
var client_retry = 0
var client_server_ip
var client_server_port

func _ready():
	set_pause_mode(PAUSE_MODE_PROCESS)

func new_packet(command, args=null):
	var pckt = {'command': command}
	if args != null:
		pckt['args'] = args
	return pckt

func _common_start(player):
	players = {player.get_name(): player}
	multiplayer = true
	set_process(true)
	connect("player_connected", game_node, "_on_player_connected")
	connect("player_disconnected", game_node, "_on_player_disconnected")
	connect("disconnected", game_node, "_on_disconnected")
	global.local_player.connect("used_item", self, "_on_used_item")

func server_start(port, player):
	server = true
	udp.listen(port)
	_common_start(player)

func client_start(ip, port, player):
	server = false
	udp.listen(0)
	client_server_ip = ip
	client_server_port = port
	udp.set_send_address(ip, port)
	udp.put_var(new_packet(CMD_CS_CONNECT, player.get_name()))
	client_ping = OS.get_unix_time()
	_common_start(player)

func client_stop():
	close()
	emit_signal("disconnected")

func server_send(pckt, ip, port):
	udp.set_send_address(ip, port)
	udp.put_var(pckt)

func server_broadcast(pckt, except=null):
	for player in clients.keys():
		if player != except:
			var client = clients[player]
			server_send(pckt, client.ip, client.port)

func server_send_to_player(pckt, player):
	server_send(pckt, clients[player].ip, clients[player].port)

func client_send(pckt):
	udp.put_var(pckt)

func server_player_disconnect(player_name):
	emit_signal("player_disconnected", players[player_name])
	players.erase(player_name)
	clients.erase(player_name)
	server_broadcast(new_packet(CMD_SC_PLAYER_DISCONNECTED, player_name))

func process_client(pckt, delta):
	if not client_connected:
		if pckt.command == CMD_SC_CONNECT_ACCEPT:
			client_connected = true
			print("Server accepted connection")
			for player_name in pckt.args:
				if not player_name in players.keys():
					var player = global.add_player(game_node, player_name, false)
					emit_signal("player_connected", player)
					players[player_name] = player
			for player_name in players.keys():
				if not player_name in pckt.args:
					emit_signal("player_disconnected", players[player_name])
					players.erase(player_name)
	elif pckt.command == CMD_SC_PING:
		client_send(new_packet(CMD_CS_PONG))
		client_ping = OS.get_unix_time()
		client_retry = 0
	elif pckt.command == CMD_SC_PONG:
		client_ping = OS.get_unix_time()
		client_retry = 0
	elif pckt.command == CMD_SC_MOVE:
		if pckt.args.player in players.keys():
			players[pckt.args.player].set_global_transform(pckt.args.transform)
	elif pckt.command == CMD_SC_DAMAGE:
		if pckt.args.player in players.keys():
			players[pckt.args.player].damage(pckt.args.damage, pckt.args.regenerable, false)
	elif pckt.command == CMD_SC_ATTACK:
		if pckt.args.player in players.keys():
			players[pckt.args.player].weapon_node.set_rotation_deg(Vector3(pckt.args.rot, 0, 0))
	elif pckt.command == CMD_SC_DIE:
		if pckt.args in players.keys():
			if players[pckt.args].hp > 0:
				players[pckt.args].die(false)
	elif pckt.command == CMD_SC_USE:
		if pckt.args.player in players.keys():
			players[pckt.args.player].items[pckt.args.item].use()
	elif pckt.command == CMD_SC_USERNAME_IN_USE:
		client_stop()
	elif pckt.command == CMD_SC_PLAYER_CONNECTED:
		players[pckt.args.player] = global.add_player(game_node, pckt.args.player, false)
		players[pckt.args.player].set_global_transform(pckt.args.transform)
		emit_signal("player_connected", players[pckt.args.player])
	elif pckt.command == CMD_SC_PLAYER_DISCONNECTED:
		emit_signal("player_disconnected", players[pckt.args])
		players.erase(pckt.args)
	elif pckt.command == CMD_SC_DOWN:
		client_stop()
		print("Server shutdown!")

func process_server(pckt, delta):
	if pckt.command == CMD_CS_CONNECT:
		var player_name = pckt.args
		if player_name in players.keys():
			udp.set_send_address(udp.get_packet_ip(), udp.get_packet_port())
			udp.put_var(new_packet(CMD_SC_USERNAME_IN_USE))
		else:
			var player = global.add_player(game_node, player_name, false)
			players[player_name] = player
			clients[player_name] = {
				'ip': udp.get_packet_ip(),
				'port': udp.get_packet_port(),
				'ping': OS.get_unix_time(),
				'retry': 0
			}
			var args = {'player': player_name, 'transform': players[player_name].get_global_transform()}
			server_broadcast(new_packet(CMD_SC_PLAYER_CONNECTED, args), player_name)
			server_send_to_player(new_packet(CMD_SC_CONNECT_ACCEPT, players.keys()), player_name)
			emit_signal("player_connected", player)
	elif pckt.command == CMD_CS_MOVE:
		if pckt.args.player in players.keys():
			server_broadcast(new_packet(CMD_SC_MOVE, pckt.args), pckt.args.player)
			players[pckt.args.player].set_global_transform(pckt.args.transform)
	elif pckt.command == CMD_CS_DAMAGE:
		if pckt.args.player in players.keys():
			server_broadcast(new_packet(CMD_SC_DAMAGE, pckt.args), pckt.args.player)
			players[pckt.args.player].damage(pckt.args.damage, pckt.args.regenerable, false)
	elif pckt.command == CMD_CS_ATTACK:
		if pckt.args.player in players.keys():
			server_broadcast(new_packet(CMD_SC_ATTACK, pckt.args), pckt.args.player)
			players[pckt.args.player].weapon_node.set_rotation_deg(Vector3(pckt.args.rot, 0, 0))
	elif pckt.command == CMD_CS_DIE:
		if pckt.args in players.keys():
			server_broadcast(new_packet(CMD_SC_DIE, pckt.args), pckt.args)
			if players[pckt.args].hp > 0:
				players[pckt.args].die(false)
	elif pckt.command == CMD_CS_USE:
		if pckt.args.player in players.keys():
			players[pckt.args.player].items[pckt.args.item].use()
	elif pckt.command == CMD_CS_DISCONNECT:
		server_player_disconnect(pckt.args)
	elif pckt.command == CMD_CS_PING:
		server_send_to_player(new_packet(CMD_SC_PONG), pckt.args)
		clients[pckt.args].ping = OS.get_unix_time()
		clients[pckt.args].retry = 0
	elif pckt.command == CMD_CS_PONG:
		clients[pckt.args].ping = OS.get_unix_time()
		clients[pckt.args].retry = 0

func _process(delta):
	if udp.get_available_packet_count() > 0:
		var pckt = udp.get_var()
		if typeof(pckt) == TYPE_DICTIONARY:
			if server:
				process_server(pckt, delta)
			else:
				process_client(pckt, delta)
		else:
			print("Invalid Variant received!")

	if server:
		for player in clients.keys():
			var client = clients[player]
			if OS.get_unix_time() - client.ping > SERVER_PING_TIMEOUT:
				if client.retry > PING_RETRY:
					server_player_disconnect(player)
				else:
					server_send_to_player(new_packet(CMD_SC_PING, player), player)
					client.ping = OS.get_unix_time()
					client.retry += 1
	else:
		if OS.get_unix_time() - client_ping > CLIENT_PING_TIMEOUT:
			if client_retry > PING_RETRY:
				client_stop()
				print("Server didn't reply!")
			else:
				client_send(new_packet(CMD_CS_PING, global.local_player.get_name()))
				client_ping = OS.get_unix_time()
				client_retry += 1

func close():
	set_process(false)
	if udp.is_listening():
		udp.close()
	if multiplayer:
		if server:
			if clients.size() > 0:
				print("Sending shutdown command to clients")
				server_broadcast(new_packet(CMD_SC_DOWN))
		elif client_connected:
			print("Sending disconnect command to server")
			udp.put_var(new_packet(CMD_CS_DISCONNECT, global.local_player.get_name()))
	multiplayer = false
	server = false
	clients = {}
	players = {}
	client_connected = false

func _exit_tree():
	close()

func _on_used_item(item):
	var player = global.local_player
	var item_i = player.items.find(item)
	if server:
		var pckt = new_packet(CMD_SC_USE, {'player': player.get_name(), 'item': item_i})
		server_broadcast(pckt)
	else:
		var pckt = new_packet(CMD_CS_USE, {'player': player.get_name(), 'item': item_i})
		udp.put_var(pckt)

