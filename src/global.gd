extends Node

var gravity = -10

var multiplayer = false
var packet
var clients = []
var server = false

var player_scn = preload("res://scene/player.tscn")

func add_player(game, name, local, translation):
	var player = player_scn.instance()
	player.set_name(name)
	var body = player.get_node("body")
	body.init(local, 150, 100)
	body.set_translation(translation)
	game.get_node("player_spawn").add_child(player)
	return player

func start_game(local, remote=[]):
	var game = preload("res://scene/game.tscn").instance()
	get_node("/root/").add_child(game)
	var i = 1
	for name in remote:
		add_player(game, name, false, Vector3(i, 0, 0))
		i += 1
	var local_player = add_player(game, local, true, Vector3())
	local_player.get_node("yaw/pitch/camera").make_current()
	get_tree().set_current_scene(game)
