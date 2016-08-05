extends Node

#Autoload

var multiplayer = false
var server = false
onready var udp = PacketPeerUDP.new()
var clients = {}
var players = []
var local_player
var spawn_node

signal player_connected
signal player_disconnected
signal disconnected

#Client to Server
const CMD_CS_CONNECT = 0
const CMD_CS_MOVE = 1
const CMD_CS_DAMAGE = 2
const CMD_CS_DISCONNECT = 99

#Server to Client
const CMD_SC_CLIENT_CONNECTED = 100
const CMD_SC_CONNECT_ACCEPT = 101
const CMD_SC_USERNAME_IN_USE = 102
const CMD_SC_MAX_PLAYERS = 103
const CMD_SC_CLIENT_DISCONNECTED = 110
const CMD_SC_MOVE = 111
const CMD_SC_DAMAGE = 112
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

func _common_start(username):
	multiplayer = true
	players = [username]
	local_player = username
	set_process(true)

func server_start(port, username):
	server = true
	udp.listen(port)
	_common_start(username)

func client_start(ip, port, username):
	server = false
	udp.listen(0)
	udp.set_send_address(ip, port)
	udp.put_var(new_packet(CMD_CS_CONNECT, username))
	var connect_timeout = Timer.new()
	connect_timeout.set_wait_time(CLIENT_CONNECT_TIMEOUT)
	connect_timeout.set_one_shot(true)
	add_child(connect_timeout)
	connect_timeout.connect("timeout", self, "_on_connect_timeout")
	connect_timeout.start()
	_common_start(username)

func _on_connect_timeout():
	if not client_connected:
		close()
		emit_signal("disconnected")

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
		if spawn_node.has_node(pckt.args.player):
			spawn_node.get_node(pckt.args.player).set_global_transform(pckt.args.transform)
	elif pckt.command == CMD_SC_DAMAGE:
		if spawn_node.has_node(pckt.args.player):
			spawn_node.get_node(pckt.args.player + "/body").damage(pckt.args.damage, pckt.args.regenerable)
	elif pckt.command == CMD_SC_USERNAME_IN_USE:
		close()
		emit_signal("disconnected")
	elif pckt.command == CMD_SC_CLIENT_CONNECTED:
		players.append(pckt.args)
		emit_signal("player_connected", pckt.args)
	elif pckt.command == CMD_SC_CONNECT_ACCEPT:
		client_connected = true
		print("Server accepted connection")
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
		close()
		emit_signal("disconnected")
		print("Server shutdown!")

func process_server(pckt, delta):
	if pckt.command == CMD_CS_CONNECT:
		var player = pckt.args
		if player in players:
			udp.set_send_address(udp.get_packet_ip(), udp.get_packet_port())
			udp.put_var(new_packet(CMD_SC_USERNAME_IN_USE))
		else:
			players.append(player)
			clients[player] = {'ip': udp.get_packet_ip(), 'port': udp.get_packet_port()}
			server_broadcast(new_packet(CMD_SC_CLIENT_CONNECTED, player), player)
			server_send_to_player(new_packet(CMD_SC_CONNECT_ACCEPT, players), player)
			emit_signal("player_connected", player)
	elif pckt.command == CMD_CS_MOVE:
		if spawn_node.has_node(pckt.args.player):
			server_broadcast(new_packet(CMD_SC_MOVE, pckt.args), pckt.args.player)
			spawn_node.get_node(pckt.args.player).set_global_transform(pckt.args.transform)
	elif pckt.command == CMD_CS_DAMAGE:
		if spawn_node.has_node(pckt.args.player):
			server_broadcast(new_packet(CMD_SC_DAMAGE, pckt.args), pckt.args.player)
			spawn_node.get_node(pckt.args.player + "/body").damage(pckt.args.damage, pckt.args.regenerable)
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
	players = []
	client_connected = false

func _exit_tree():
	close()


