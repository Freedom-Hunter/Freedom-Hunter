extends Node

#Autoload

var Player = preload("res://src/entities/player.gd")

onready var udp = PacketPeerUDP.new()

var multiplayer = false
var server = false
var clients = {}
var players = {}
var local_player

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
const CMD_CS_DISCONNECT = 99

#Server to Client
const CMD_SC_CLIENT_CONNECTED = 100
const CMD_SC_CONNECT_ACCEPT = 101
const CMD_SC_USERNAME_IN_USE = 102
const CMD_SC_MAX_PLAYERS = 103
const CMD_SC_CLIENT_DISCONNECTED = 110
const CMD_SC_MOVE = 111
const CMD_SC_DAMAGE = 112
const CMD_SC_ATTACK = 113
const CMD_SC_DIE = 114
const CMD_SC_DOWN = 200

var client_connected = false
const CLIENT_CONNECT_TIMEOUT = 5

func _ready():
	set_pause_mode(PAUSE_MODE_PROCESS)

func new_packet(command, args=null):
	var pckt = {'command': command}
	if args != null:
		pckt['args'] = args
	return pckt

func _common_start(player):
	players = {player.get_name(): player}
	local_player = player.get_name()
	multiplayer = true
	set_process(true)
	connect("player_connected", game_node, "_on_player_connected")
	connect("player_disconnected", game_node, "_on_player_disconnected")
	connect("disconnected", game_node, "_on_disconnected")

func server_start(port, player):
	server = true
	udp.listen(port)
	_common_start(player)

func client_start(ip, port, player):
	server = false
	udp.listen(0)
	udp.set_send_address(ip, port)
	udp.put_var(new_packet(CMD_CS_CONNECT, player.get_name()))
	var connect_timeout = Timer.new()
	connect_timeout.set_wait_time(CLIENT_CONNECT_TIMEOUT)
	connect_timeout.set_one_shot(true)
	add_child(connect_timeout)
	connect_timeout.connect("timeout", self, "_on_connect_timeout")
	connect_timeout.start()
	_common_start(player)

func _on_connect_timeout():
	if not client_connected:
		close()
		emit_signal("disconnected")

func server_broadcast(pckt, except=null):
	for player in clients.keys():
		if player != except:
			var client = clients[player]
			#print("sending '%s' to %s [%s:%s]" % [pckt, player, client.ip, client.port])
			udp.set_send_address(client.ip, client.port)
			udp.put_var(pckt)

func server_send_to_player(pckt, player):
	udp.set_send_address(clients[player].ip, clients[player].port)
	udp.put_var(pckt)

func process_client(pckt, delta):
	if pckt.command == CMD_SC_MOVE:
		if spawn_node.has_node(pckt.args.player):
			spawn_node.get_node(pckt.args.player).set_global_transform(pckt.args.transform)
	elif pckt.command == CMD_SC_DAMAGE:
		if spawn_node.has_node(pckt.args.player):
			var player = spawn_node.get_node(pckt.args.player + "/body")
			player.damage(pckt.args.damage, pckt.args.regenerable, false)
	elif pckt.command == CMD_SC_ATTACK:
		if spawn_node.has_node(pckt.args.player):
			var player = spawn_node.get_node(pckt.args.player + "/body")
			player.weapon_node.set_rotation_deg(Vector3(pckt.args.rot, 0, 0))
	elif pckt.command == CMD_SC_DIE:
		if spawn_node.has_node(pckt.args):
			var player = spawn_node.get_node(pckt.args + "/body")
			if player.hp > 0:
				player.die(false)
	elif pckt.command == CMD_SC_USERNAME_IN_USE:
		close()
		emit_signal("disconnected")
	elif pckt.command == CMD_SC_CLIENT_CONNECTED:
		players.append(pckt.args)
		emit_signal("player_connected", players[pckt.args])
	elif pckt.command == CMD_SC_CONNECT_ACCEPT:
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
	elif pckt.command == CMD_SC_CLIENT_DISCONNECTED:
		emit_signal("player_disconnected", players[pckt.args])
		players.erase(pckt.args)
	elif pckt.command == CMD_SC_DOWN:
		close()
		emit_signal("disconnected")
		print("Server shutdown!")

func process_server(pckt, delta):
	if pckt.command == CMD_CS_CONNECT:
		var player_name = pckt.args
		if player_name in players.keys():
			udp.set_send_address(udp.get_packet_ip(), udp.get_packet_port())
			udp.put_var(new_packet(CMD_SC_USERNAME_IN_USE))
		else:
			print(game_node.get_path())
			var player = global.add_player(game_node, player_name, false)
			players[player_name] = player
			clients[player_name] = {'ip': udp.get_packet_ip(), 'port': udp.get_packet_port()}
			server_broadcast(new_packet(CMD_SC_CLIENT_CONNECTED, player_name), player_name)
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
	elif pckt.command == CMD_CS_DISCONNECT:
		var player_name = pckt.args
		emit_signal("player_disconnected", players[player_name])
		players.erase(player_name)
		clients.erase(player_name)

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
			udp.put_var(new_packet(CMD_CS_DISCONNECT, local_player))
	multiplayer = false
	server = false
	clients = {}
	players = {}
	client_connected = false

func _exit_tree():
	close()


