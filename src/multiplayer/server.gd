extends "common.gd"

const PING_TIMEOUT = 3
const PING_RETRY = 3

var clients = {}

func start(game, port):
	.start(game)
	if udp.listen(port) == OK:
		return true
	else:
		return false

func send(pckt, ip, port):
	udp.set_send_address(ip, port)
	udp.put_var(pckt)

func send_to_player(pckt, player):
	print("Sending %s to %s at %s:%s" % [pckt, player, clients[player].ip, clients[player].port])
	send(pckt, clients[player].ip, clients[player].port)

func broadcast(pckt, except=null):
	for player in clients.keys():
		if player != except:
			send_to_player(pckt, player)

func player_connect(player_name, ip, port):
	if player_name in clients.keys():
		send(new_packet(CMD_SC_USERNAME_IN_USE), ip, port)
		print('Refused connection from %s:%s because "%s" is in use' % [ip, port, player_name])
	else:
		clients[player_name] = {
			'ip': ip,
			'port': port,
			'ping': OS.get_unix_time(),
			'retry': 0
		}
		var player = global.add_player(game_node, player_name, false)
		players[player_name] = player
		var args = {'player': player_name, 'transform': player.get_global_transform()}
		broadcast(new_packet(CMD_SC_PLAYER_CONNECTED, args), player_name)
		send_to_player(new_packet(CMD_SC_CONNECT_ACCEPT, clients.keys()), player_name)
		print('Player "%s" connected' % player_name)

func player_disconnect(player_name):
	global.remove_player(game_node, player_name)
	clients.erase(player_name)
	players.erase(player_name)
	broadcast(new_packet(CMD_SC_PLAYER_DISCONNECTED, player_name))
	print('Player "%s" disconnected' % player_name)

func player_move(args):
	if args.player in clients.keys():
		broadcast(new_packet(CMD_SC_MOVE, args), args.player)
		players[args.player].set_global_transform(args.transform)

func player_damage(args):
	if args.player in clients.keys():
		broadcast(new_packet(CMD_SC_DAMAGE, args), args.player)
		players[args.player].damage(args.damage, args.regenerable)

func player_attack(args):
	if args.player in clients.keys():
		broadcast(new_packet(CMD_SC_ATTACK, args), args.player)
		players[args.player].weapon_node.set_rotation_deg(Vector3(args.rot, 0, 0))

func player_die(args):
	if args in clients.keys():
		broadcast(new_packet(CMD_SC_DIE, args), args)
		if players[args].hp > 0:
			players[args].die()

func player_use_item(args):
	if args.player in clients.keys():
		broadcast(new_packet(CMD_SC_USE, args), args.player)
		players[args.player].items[args.item].use()

func player_got_item(args):
	if args.player in clients.keys():
		var item = dict2inst(args.item)
		broadcast(new_packet(CMD_SC_GOT, args), args.player)
		players[args.player].add_item(item)

func ping(args):
	send_to_player(new_packet(CMD_SC_PONG, args), args)
	clients[args].ping = OS.get_unix_time()
	clients[args].retry = 0

func pong(args):
	clients[args].ping = OS.get_unix_time()
	clients[args].retry = 0

func handle_packet(pckt, ip, port):
	print("Received %s from %s:%s" % [pckt, ip, port])
	if pckt.command == CMD_CS_CONNECT:
		player_connect(pckt.args, ip, port)
	elif pckt.command == CMD_CS_MOVE:
		player_move(pckt.args)
	elif pckt.command == CMD_CS_DAMAGE:
		player_damage(pckt.args)
	elif pckt.command == CMD_CS_ATTACK:
		player_attack(pckt.args)
	elif pckt.command == CMD_CS_DIE:
		player_die(pckt.args)
	elif pckt.command == CMD_CS_USE:
		player_use_item(pckt.args)
	elif pckt.command == CMD_CS_GOT:
		player_got_item(pckt.args)
	elif pckt.command == CMD_CS_DISCONNECT:
		player_disconnect(pckt.args)
	elif pckt.command == CMD_CS_PING:
		ping(pckt.args)
	elif pckt.command == CMD_CS_PONG:
		pong(pckt.args)
	else:
		print("Unknown command %s received" % pckt.command)

func stop():
	.stop()
	if clients.size() > 0:
		print("Sending shutdown command to clients")
		broadcast(new_packet(CMD_SC_DOWN))
	clients = {}
	players = {}

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

func _exit_tree():
	stop()

func local_player_move(transform):
	var name = global.local_player.get_name()
	broadcast(new_packet(CMD_SC_MOVE, {'player': name, 'transform': transform}))

func local_player_attack(rot):
	var name = global.local_player.get_name()
	broadcast(new_packet(CMD_SC_ATTACK, {'player': name, 'rot': rot}))

func local_player_died():
	var name = global.local_player.get_name()
	broadcast(new_packet(CMD_SC_DIE, name))

func local_player_damage(dmg, reg):
	var name = global.local_player.get_name()
	broadcast(new_packet(CMD_SC_DAMAGE, {'damage': dmg, 'regenerable': reg}))

func local_player_used_item(item):
	var player = global.local_player
	var item_i = player.items.find(item)
	broadcast(new_packet(CMD_SC_USE, {'player': player.get_name(), 'item': item_i}))

func local_player_got_item(item):
	var name = global.local_player.get_name()
	var item_dict = inst2dict(item)
	broadcast(new_packet(CMD_SC_GOT, {'player': name, 'item': item_dict}))
