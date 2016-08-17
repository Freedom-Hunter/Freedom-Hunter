#Client to Server
	# System comands
const CMD_CS_CONNECT = 0
const CMD_CS_DISCONNECT = 10
const CMD_CS_PING = 98
const CMD_CS_PONG = 99
	# Game comands
const CMD_CS_MOVE = 100
const CMD_CS_DAMAGE = 120
const CMD_CS_L_ATTACK = 130
const CMD_CS_R_ATTACK = 140
const CMD_CS_DIE = 150
const CMD_CS_USE = 160
const CMD_CS_GOT = 170

#Server to Client
	# System comands
const CMD_SC_PLAYER_CONNECTED = 0
const CMD_SC_CONNECT_ACCEPT = 1
const CMD_SC_USERNAME_IN_USE = 2
const CMD_SC_MAX_PLAYERS = 3
const CMD_SC_PLAYER_DISCONNECTED = 10
const CMD_SC_DOWN = 97
const CMD_SC_PING = 98
const CMD_SC_PONG = 99
	# Game comands
const CMD_SC_MOVE = 100
const CMD_SC_DAMAGE = 120
const CMD_SC_L_ATTACK = 130
const CMD_SC_R_ATTACK = 140
const CMD_SC_DIE = 150
const CMD_SC_USE = 160
const CMD_SC_GOT = 170
const CMD_SC_M_MOVE = 500
const CMD_SC_M_ATTACK = 501

var udp
var players
var monsters
var game_node
var spawn_node
var monster_spawn_node
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
	monster_spawn_node = game.get_node("monster_spawn")
	players = {}
	monsters = {}
	for player in spawn_node.get_children():
		players[player.get_name()] = player.get_node("body")
	for monster in monster_spawn_node.get_children():
		monsters[monster.get_name()] = monster
	if global.local_player != null:
		global.local_player.connect("used_item", self, "local_player_used_item")
		global.local_player.connect("got_item", self, "local_player_got_item")

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
