extends Control

var players = ["local"]

func _ready():
	print("Waiting for players...")
	set_process(true)

func _process(delta):
	if global.packet.get_available_packet_count() > 0:
		var name = global.packet.get_var()
		global.clients.append({'ip': global.packet.get_packet_ip(), 'port': global.packet.get_packet_port(), 'name': name})
		get_node("list").add_child(Label.new().set_text(name))
		players.append(name)

func _on_play_pressed():
	if players.size() > 0:
		for client in global.clients:
			print("Invio la lista a %s:%s" % [client['ip'], client['port']])
			global.packet.set_send_address(client['ip'], client['port'])
			global.packet.put_var(players)
		var local = players[0]
		players.pop_front()
		global.start_game(local, players)
		queue_free()
