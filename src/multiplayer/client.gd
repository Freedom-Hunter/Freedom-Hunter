extends "common.gd"

const PING_TIMEOUT = 3
const PING_RETRY = 3

var server_ip
var server_port
var connected = false
var ping
var retry = 0

func start(ip, port):
	if .start(0):
		server_ip = ip
		server_port = port
		udp.set_dest_address(ip, port)
		udp.put_var(new_packet(CMD_CS_CONNECT, global.local_player.get_name()))
		ping = OS.get_unix_time()
		return true
	return false

func send(pckt):
	udp.put_var(pckt)

func connection_accepted(args):
	connected = true
	print("Server accepted connection")
	for player_name in args:
		if not player_name in players.keys():
			var player = global.add_player(player_name, false)
			emit_signal("player_connected", player)
			players[player_name] = player
			entities[player_name] = player
	for player_name in players.keys():
		if not player_name in args:
			emit_signal("player_disconnected", players[player_name])
			players.erase(player_name)
			entities.erase(player_name)

func ping(args):
	send(new_packet(CMD_CS_PONG, global.local_player.get_name()))
	ping = OS.get_unix_time()
	retry = 0

func pong(args):
	ping = OS.get_unix_time()
	retry = 0

func entity_spawn(args):
	entities[args.entity] = global.add_monster(args.name, load(args.scene))

func entity_respawn(args):
	if args.entity in entities.keys():
		entities[args].respawn()

func entity_move(args):
	if args.entity in entities.keys():
		entities[args.entity].set_global_transform(args.transform)

func entity_damage(args):
	if args.entity in entities.keys():
		entities[args.entity].hp = args.hp
		entities[args.entity].regenerable_hp = args.reg

func entity_attack(args):
	if args.entity in entities.keys():
		entities[args.entity].attack(args.attack)

func entity_die(args):
	if args in entities.keys():
		entities[args].die()

func player_use_item(args):
	if args.player in players.keys():
		players[args.player].items[args.item].use()

func player_got_item(args):
	if args.player in players.keys():
		var item = dict2inst(args.item)
		players[args.player].add_item(item)

func player_connected(args):
	players[args.player] = global.add_player(args.player, false)
	players[args.player].set_global_transform(args.transform)
	entities[args.player] = players[args.player]
	emit_signal("player_connected", players[args.player])

func player_disconnected(args):
	emit_signal("player_disconnected", players[args])
	players.erase(args)
	entities.erase(args)

func handle_packet(pckt, ip, port):
	#print("Received %s from %s:%s" % [pckt, ip, port])
	if not connected:
		if pckt.command == CMD_SC_CONNECT_ACCEPT:
			connection_accepted(pckt.args)
		elif pckt.command == CMD_SC_USERNAME_IN_USE:
			global.stop_game()
	elif pckt.command == CMD_SC_PING:
		ping(pckt.args)
	elif pckt.command == CMD_SC_PONG:
		pong(pckt.args)
	elif pckt.command == CMD_SC_MOVE:
		entity_move(pckt.args)
	elif pckt.command == CMD_SC_DAMAGE:
		entity_damage(pckt.args)
	elif pckt.command == CMD_SC_ATTACK:
		entity_attack(pckt.args)
	elif pckt.command == CMD_SC_DIE:
		entity_die(pckt.args)
	elif pckt.command == CMD_SC_USE:
		player_use_item(pckt.args)
	elif pckt.command == CMD_SC_GOT:
		player_got_item(pckt.args)
	elif pckt.command == CMD_SC_PLAYER_CONNECTED:
		player_connected(pckt.args)
	elif pckt.command == CMD_SC_PLAYER_DISCONNECTED:
		player_disconnected(pckt.args)
	elif pckt.command == CMD_SC_DOWN:
		global.stop_game()
		print("Server shutdown!")
	else:
		printerr("Unknown command %s received" % pckt.command)

func process(delta):
	.process(delta)

	if OS.get_unix_time() - ping > PING_TIMEOUT:
		if retry > PING_RETRY:
			global.stop_game()
			printerr("Server didn't reply!")
		else:
			send(new_packet(CMD_CS_PING, global.local_player.get_name()))
			ping = OS.get_unix_time()
			retry += 1

func stop():
	if connected:
		print("Sending disconnect command to server")
		send(new_packet(CMD_CS_DISCONNECT, global.local_player.get_name()))
	connected = false
	.stop()

func local_entity_spawn(entity, scene):
	send(new_packet(CMD_CS_SPAWN, {'entity': entity, 'scene': scene}))

func local_entity_respawn(entity):
	send(new_packet(CMD_CS_RESPAWN, entity))

func local_entity_move(entity, transform):
	send(new_packet(CMD_CS_MOVE, {'entity': entity, 'transform': transform}))

func local_entity_attack(entity, attack):
	send(new_packet(CMD_CS_ATTACK, {'entity': entity, 'attack': attack}))

func local_entity_died(entity):
	send(new_packet(CMD_CS_DIE, entity))

func local_entity_damage(entity, hp, reg):
	send(new_packet(CMD_CS_DAMAGE, {'entity': entity, 'hp': hp, 'reg': reg}))

func local_player_used_item(item):
	var player = global.local_player
	var item_i = player.items.find(item)
	send(new_packet(CMD_CS_USE, {'player': player.get_name(), 'item': item_i}))

func local_player_got_item(item):
	var name = global.local_player.get_name()
	var item_dict = inst2dict(item)
	send(new_packet(CMD_CS_GOT, {'player': name, 'item': item_dict}))
