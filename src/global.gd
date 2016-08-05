extends Node

var gravity = -10

var player_scn = preload("res://scene/player.tscn")

func add_player(game, name, local, translation):
	var player = player_scn.instance()
	player.set_name(name)
	var body = player.get_node("body")
	body.init(local, 150, 100)
	body.set_translation(translation)
	game.get_node("player_spawn").add_child(player)
	return player

func start_game(local_player_name):
	var game = preload("res://scene/game.tscn").instance()
	get_node("/root/").add_child(game)
	var local_player = add_player(game, local_player_name, true, Vector3())
	local_player.get_node("yaw/pitch/camera").make_current()
	get_node("/root/game/hud").init(local_player)
	if networking.multiplayer:
		get_node("/root/game").begin_multiplayer()
		networking.spawn_node = game.get_node("player_spawn")
	get_tree().set_current_scene(game)
