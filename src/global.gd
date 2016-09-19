extends Node

const ELEMENTS = ["Fire", "Water", "Ice", "Thunder", "Dragon", "Poison", "Paralysis"]
var gravity = -10

var player_scn = preload("res://scene/player.tscn")

var game = null
var local_player = null

func add_monster(scene):
	assert(game != null)
	var monster = scene.instance()
	game.get_node("monster_spawn").add_child(monster)
	monster.init()

func add_player(name, local=false):
	assert(game != null)
	var player = player_scn.instance()
	player.set_name(name)
	game.get_node("player_spawn").add_child(player)
	player.get_node("body").init(local, 150, 100)
	game.get_node("hud").player_connected(name)
	if local:
		player.set_network_mode(NETWORK_MODE_MASTER)
		local_player = player.get_node("body")
	else:
		player.set_network_mode(NETWORK_MODE_SLAVE)
	local_player.camera_node.make_current()
	return player.get_node("body")

func remove_player(name):
	game.get_node("player_spawn").get_node(name).queue_free()
	game.get_node("hud").player_disconnected(name)

func start_game(local_player_name):
	print("Loading game...")
	game = preload("res://scene/game.tscn").instance()
	get_node("/root/").add_child(game)
	add_monster(load("res://scene/monsters/dragon.tscn"))
	if local_player_name != null:
		add_player(local_player_name, true)
		game.get_node("hud").init()
	get_tree().set_current_scene(game)

func stop_game():
	if game != null:
		game.queue_free()
	get_node("/root/networking").stop()
	local_player = null
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().set_pause(false)
	get_tree().change_scene("res://scene/main_menu.tscn")

func exit_clean():
	var networking = get_node("/root/networking")
	networking.stop()
	if networking.multiplayer:
		if networking.lobby.player_id != null:
			networking.lobby.unregister_player()
			yield(networking.lobby.http, "request_completed")
		if networking.lobby.server_id != null:
			networking.lobby.unregister_server()
			yield(networking.lobby.http, "request_completed")
	get_tree().quit()

func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		exit_clean()
