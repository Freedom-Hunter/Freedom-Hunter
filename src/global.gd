extends Node

var gravity = -10

var player_scn = preload("res://scene/player.tscn")

var local_player = null

func add_monster(game, scene):
	var monster = scene.instance()
	game.get_node("monster_spawn").add_child(monster)
	monster.init()

func add_player(game, name, local):
	var player = player_scn.instance()
	player.set_name(name)
	player.get_node("body").init(local, 150, 100)
	game.get_node("player_spawn").add_child(player)
	game.get_node("hud").player_connected(name)
	if local_player != null:
		local_player.camera_node.make_current()
	return player.get_node("body")

func remove_player(game, name):
	game.get_node("player_spawn").get_node(name).queue_free()
	game.get_node("hud").player_disconnected(name)

func start_game(local_player_name):
	var game = preload("res://scene/game.tscn").instance()
	get_node("/root/").add_child(game)
	add_monster(game, load("res://scene/monsters/dragon.tscn"))
	if local_player_name != null:
		local_player = add_player(game, local_player_name, true)
		game.get_node("hud").init()
	get_tree().set_current_scene(game)
	return game

func stop_game():
	local_player = null
	get_node("/root/game").queue_free()
	get_node("/root/networking").stop()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().set_pause(false)
	get_tree().change_scene("res://scene/main_menu.tscn")
