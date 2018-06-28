extends Node

var gravity = -10

const PlayerScene = preload("res://data/scenes/player.tscn")

var game
var players_spawn
var monsters_spawn

var local_player = null

static func add_entity(_name, scene, spawn, id=1):
	var entity = scene.instance()
	entity.set_network_master(id)
	entity.set_name(_name)
	spawn.add_child(entity)
	return entity

func add_monster(_name, scene):
	return add_entity(_name, scene, monsters_spawn)

func add_player(_name, id=1, transform=null):
	var player = add_entity(_name, PlayerScene, players_spawn, id)
	if id == networking.unique_id:
		prints(_name, "is local player")
		local_player = player
	else:
		prints(_name, "is remote player")
	if transform != null:
		player.transform = transform
	game.get_node("hud").player_connected(_name)
	return player

func remove_player(_name):
	players_spawn.get_node(_name).queue_free()
	game.get_node("hud").player_disconnected(_name)

func start_game(local_player_name):
	game = preload("res://data/scenes/game.tscn").instance()
	get_node("/root/").add_child(game)
	players_spawn = game.get_node("player_spawn")
	monsters_spawn = game.get_node("monster_spawn")
	add_monster("Dragon", preload("res://data/scenes/monsters/dragon.tscn"))
	if local_player_name != null:
		local_player = add_player(local_player_name, networking.unique_id)
		game.get_node("hud").init()
	get_tree().set_current_scene(game)
	return game

func stop_game():
	if game != null:
		game.queue_free()
		game = null
	get_node("/root/networking").stop()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().set_pause(false)
	get_tree().change_scene("res://data/scenes/main_menu.tscn")

func exit_clean():
	var networking = get_node("/root/networking")
	networking.stop()
	get_tree().quit()

func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		exit_clean()
