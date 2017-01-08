extends "common.gd"

const PING_TIMEOUT = 3
const PING_RETRY = 3

var clients = {}

func send(pckt, ip, port):
	udp.set_send_address(ip, port)
	udp.put_var(pckt)

func send_to_player(pckt, player):
	#print("Sending %s to %s at %s:%s" % [pckt, player, clients[player].ip, clients[player].port])
	send(pckt, clients[player].ip, clients[player].port)

func broadcast(pckt, except=null):
	for player in clients.keys():
		if player != except:
			send_to_player(pckt, player)

func player_connect(player_name, ip, port):
	if player_name in players.keys():
		send(new_packet(CMD_SC_USERNAME_IN_USE), ip, port)
		printerr('Refused connection from %s:%s because "%s" is in use' % [ip, port, player_name])
	else:
		clients[player_name] = {
			'ip': ip,
			'port': port,
			'ping': OS.get_unix_time(),
			'retry': 0
		}
		var player = global.add_player(player_name, false)
		players[player_name] = player
		entities[player_name] = player
		var args = {'player': player_name, 'transform': player.get_global_transform()}
		broadcast(new_packet(CMD_SC_PLAYER_CONNECTED, args), player_name)
		send_to_player(new_packet(CMD_SC_CONNECT_ACCEPT, players.keys()), player_name)
		print('Player "%s" connected' % player_name)

func player_disconnect(player_name):
	global.remove_player(player_name)
	clients.erase(player_name)
	players.erase(player_name)
	entities.erase(player_name)
	broadcast(new_packet(CMD_SC_PLAYER_DISCONNECTED, player_name))
	print('Player "%s" disconnected' % player_name)

func entity_spawn(sender, args):
	entities[args.entity] = global.add_monster(args.entity, load(args.scene))
	broadcast(new_packet(CMD_SC_SPAWN, args), sender)

func entity_respawn(sender, args):
	if args in entities.keys():
		entities[args].respawn()
		broadcast(new_packet(CMD_SC_RESPAWN, args), sender)

func entity_move(sender, args):
	if args.entity in entities.keys():
		broadcast(new_packet(CMD_SC_MOVE, args), sender)
		entities[args.entity].set_global_transform(args.transform)

func entity_damage(sender, args):
	if args.entity in entities.keys():
		broadcast(new_packet(CMD_SC_DAMAGE, args), sender)
		entities[args.entity].hp = args.hp
		entities[args.entity].regenerable_hp = args.reg

func entity_attack(sender, args):
	if args.entity in entities.keys():
		broadcast(new_packet(CMD_SC_ATTACK, args), sender)
		entities[args.entity].attack(args.attack)

func entity_die(sender, args):
	if args in entities.keys():
		broadcast(new_packet(CMD_SC_DIE, args), sender)
		entities[args].die()
		entities.erase(args)

func player_use_item(sender, args):
	if args.player in clients.keys():
		broadcast(new_packet(CMD_SC_USE, args), sender)
		players[args.player].items[args.item].use()

func player_got_item(sender, args):
	if args.player in clients.keys():
		var item = dict2inst(args.item)
		broadcast(new_packet(CMD_SC_GOT, args), sender)
		players[args.player].add_item(item)

func ping(client_id):
	send_to_player(new_packet(CMD_SC_PONG, client_id), client_id)
	clients[client_id].ping = OS.get_unix_time()
	clients[client_id].retry = 0

func pong(client_id):
	clients[client_id].ping = OS.get_unix_time()
	clients[client_id].retry = 0

func handle_packet(pckt, ip, port):
	if pckt.command != CMD_CS_CONNECT and not pckt.sender in clients.keys():
		printerr("Sender %s from %s:%s is not connected! Ignoring packet..." % [pckt.sender, ip, port])
		return
	#print("Received %s from %s:%s by %s" % [pckt, ip, port, pckt.sender])
	if pckt.command == CMD_CS_CONNECT:
		player_connect(pckt.args, ip, port)
	elif pckt.command == CMD_CS_PING:
		ping(pckt.sender)
	elif pckt.command == CMD_CS_PONG:
		pong(pckt.sender)
	elif pckt.command == CMD_CS_SPAWN:
		entity_spawn(pckt.sender, pckt.args)
	elif pckt.command == CMD_CS_RESPAWN:
		entity_respawn(pckt.sender, pckt.args)
	elif pckt.command == CMD_CS_MOVE:
		entity_move(pckt.sender, pckt.args)
	elif pckt.command == CMD_CS_DAMAGE:
		entity_damage(pckt.sender, pckt.args)
	elif pckt.command == CMD_CS_ATTACK:
		entity_attack(pckt.sender, pckt.args)
	elif pckt.command == CMD_CS_DIE:
		entity_die(pckt.sender, pckt.args)
	elif pckt.command == CMD_CS_USE:
		player_use_item(pckt.sender, pckt.args)
	elif pckt.command == CMD_CS_GOT:
		player_got_item(pckt.sender, pckt.args)
	elif pckt.command == CMD_CS_DISCONNECT:
		player_disconnect(pckt.args)
	else:
		printerr("Unknown command %s received" % pckt.command)

func stop():
	if clients.size() > 0:
		print("Sending shutdown command to clients")
		broadcast(new_packet(CMD_SC_DOWN))
	.stop()

func process(delta):
	.process(delta)
	for player in clients.keys():
		var client = clients[player]
		if OS.get_unix_time() - client.ping > PING_TIMEOUT:
			if client.retry > PING_RETRY:
				player_disconnect(player)
			else:
				send_to_player(new_packet(CMD_SC_PING, player), player)
				client.ping = OS.get_unix_time()
				client.retry += 1

func local_entity_spawn(entity, scene):
	broadcast(new_packet(CMD_SC_SPAWN, {'entity': entity, 'scene': scene}))

func local_entity_respawn(entity):
	broadcast(new_packet(CMD_SC_RESPAWN, entity))

func local_entity_move(entity, transform):
	broadcast(new_packet(CMD_SC_MOVE, {'entity': entity, 'transform': transform}))

func local_entity_attack(entity, attack):
	broadcast(new_packet(CMD_SC_ATTACK, {'entity': entity, 'attack': attack}))

func local_entity_died(entity):
	broadcast(new_packet(CMD_SC_DIE, entity))

func local_entity_damage(entity, hp, reg):
	broadcast(new_packet(CMD_SC_DAMAGE, {'entity': entity, 'hp': hp, 'reg': reg}))

func local_player_used_item(item):
	var player = global.local_player
	var item_i = player.items.find(item)
	broadcast(new_packet(CMD_SC_USE, {'player': player.get_name(), 'item': item_i}))

func local_player_got_item(item):
	var name = global.local_player.get_name()
	var item_dict = inst2dict(item)
	broadcast(new_packet(CMD_SC_GOT, {'player': name, 'item': item_dict}))
