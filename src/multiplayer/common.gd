#Client to Server
	# System comands
const CMD_CS_CONNECT = 0
const CMD_CS_DISCONNECT = 10
const CMD_CS_PING = 98
const CMD_CS_PONG = 99
	# Game comands
const CMD_CS_MOVE = 100
const CMD_CS_DAMAGE = 120
const CMD_CS_ATTACK = 130
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
const CMD_SC_ATTACK = 130
const CMD_SC_DIE = 150
const CMD_SC_USE = 160
const CMD_SC_GOT = 170

var udp
var players
var monsters
var entities  # players + monsters
var game_node
var players_spawn_node
var monsters_spawn_node
var global

var player_scn = preload("res://data/scenes/player.tscn")

signal player_connected
signal player_disconnected

func new_packet(command, args=null):
	var pckt = {'sender': global.local_player.get_name(), 'command': command}
	if args != null:
		pckt['args'] = args
	return pckt

func start(game, port):
	udp = PacketPeerUDP.new()
	if udp.listen(port) == OK:
		game_node = game
		players_spawn_node = game.get_node("player_spawn")
		monsters_spawn_node = game.get_node("monster_spawn")
		players = {}
		monsters = {}
		entities = {}
		for player in players_spawn_node.get_children():
			players[player.get_name()] = player
			entities[player.get_name()] = player
		for monster in monsters_spawn_node.get_children():
			monsters[monster.get_name()] = monster
			entities[monster.get_name()] = monster
		return true
	return false

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
	while ret != null:
		handle_packet(ret.pckt, ret.ip, ret.port)
		ret = get_available_packet()

func stop():
	if udp.is_listening():
		udp.close()
	players = {}
	monsters = {}
	entities = {}
