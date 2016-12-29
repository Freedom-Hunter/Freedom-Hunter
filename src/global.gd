extends Node

var gravity = -10

var player_scn = preload("res://data/scenes/player.tscn")

var local_player = null

func add_monster(game, scene):
	var monster = scene.instance()
	game.get_node("monster_spawn").add_child(monster)

func add_player(game, name, local):
	var player = player_scn.instance()
	player.set_name(name)
	game.get_node("player_spawn").add_child(player)
	player.local = local
	game.get_node("hud").player_connected(name)
	return player

func remove_player(game, name):
	game.get_node("player_spawn").get_node(name).queue_free()
	game.get_node("hud").player_disconnected(name)

func start_game(local_player_name):
	var game = preload("res://data/scenes/game.tscn").instance()
	get_node("/root/").add_child(game)
	add_monster(game, load("res://data/scenes/monsters/dragon.tscn"))
	if local_player_name != null:
		local_player = add_player(game, local_player_name, true)
		game.get_node("hud").init()
	get_tree().set_current_scene(game)
	return game

func stop_game():
	get_node("/root/game").queue_free()
	get_node("/root/networking").stop()
	local_player = null
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().set_pause(false)
	get_tree().change_scene("res://data/scenes/main_menu.tscn")

func exit_clean():
	var networking = get_node("/root/networking")
	networking.stop()
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
