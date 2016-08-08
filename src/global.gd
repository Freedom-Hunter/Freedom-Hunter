extends Node

var gravity = -10

var player_scn = preload("res://scene/player.tscn")

var local_player = null

func add_player(game, name, local):
	var player = player_scn.instance()
	player.set_name(name)
	var body = player.get_node("body")
	body.init(local, 150, 100)
	game.get_node("player_spawn").add_child(player)
	return player.get_node("body")

func start_game(local_player_name, multiplayer=false):
	var game = preload("res://scene/game.tscn").instance()
	get_node("/root/").add_child(game)
	local_player = add_player(game, local_player_name, true)
	local_player.camera_node.make_current()
	get_node("/root/game/hud").init()
	if multiplayer:
		networking.spawn_node = game.get_node("player_spawn")
		networking.game_node = game
	get_tree().set_current_scene(game)
	return local_player
