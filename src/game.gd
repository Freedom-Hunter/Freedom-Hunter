extends Node

func _ready():
	if global.multiplayer:
		set_process(true)

func _process(delta):
	if global.packet.get_available_packet_count() > 0:
		var pckt = global.packet.get_var()
		for player in get_node("player_spawn").get_children():
			var body = player.get_node("body")
			if not body.local and pckt['name'] == player.get_name():
				body.set_global_transform(pckt['transform'])
