extends Node

var gravity = -10

var player_scn = preload("res://data/scenes/player.tscn")

var game
var players_spawn
var monsters_spawn

var local_player = null

static func add_entity(name, local, scene, spawn):
	var entity = scene.instance()
	entity.set_name(name)
	if networking.multiplayer:
		entity.local = local
	spawn.add_child(entity)
	return entity

func add_monster(name, scene):
	return add_entity(name, networking.is_server(), scene, monsters_spawn)

func add_player(name, local):
	var player = add_entity(name, local, player_scn, players_spawn)
	game.get_node("hud").player_connected(name)
	return player

func remove_player(name):
	players_spawn.get_node(name).queue_free()
	game.get_node("hud").player_disconnected(name)

func start_game(local_player_name):
	game = preload("res://data/scenes/game.tscn").instance()
	get_node("/root/").add_child(game)
	players_spawn = game.get_node("player_spawn")
	monsters_spawn = game.get_node("monster_spawn")
	add_monster("Dragon", preload("res://data/scenes/monsters/dragon.tscn"))
	if local_player_name != null:
		local_player = add_player(local_player_name, true)
		game.get_node("hud").init()
	get_tree().set_current_scene(game)
	return game

func stop_game():
	game.queue_free()
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
