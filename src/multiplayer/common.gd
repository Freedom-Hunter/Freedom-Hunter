extends Node

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
const CMD_SC_MAX_clients = 103
const CMD_SC_PLAYER_DISCONNECTED = 110
const CMD_SC_MOVE = 111
const CMD_SC_DAMAGE = 112
const CMD_SC_ATTACK = 113
const CMD_SC_DIE = 114
const CMD_SC_USE = 115
const CMD_SC_PING = 150
const CMD_SC_PONG = 151
const CMD_SC_DOWN = 200

var udp
var players
var game_node
var spawn_node
var global

var player_scn = preload("res://scene/player.tscn")

signal player_connected
signal player_disconnected

func new_packet(command, args=null):
	var pckt = {'command': command}
	if args != null:
		pckt['args'] = args
	return pckt

func start(game):
	udp = PacketPeerUDP.new()
	game_node = game
	spawn_node = game.get_node("player_spawn")
	players = {}
	for player in spawn_node.get_children():
		players[player.get_name()] = player.get_node("body")

func get_available_packet():
	if udp.get_available_packet_count() > 0:
		var pckt = udp.get_var()
		var err = udp.get_packet_error()
		if err == OK and typeof(pckt) == TYPE_DICTIONARY:
			return {'pckt': pckt, 'ip': udp.get_packet_ip(), 'port': udp.get_packet_port()}
		else:
			print("Invalid packet received: error %s, type %s" % [err, typeof(pckt)])
	return null

func handle_packet(pckt, ip, port):
	pass

func process(delta):
	var ret = get_available_packet()
	if ret != null:
		handle_packet(ret.pckt, ret.ip, ret.port)

func stop():
	if udp.is_listening():
		udp.close()
