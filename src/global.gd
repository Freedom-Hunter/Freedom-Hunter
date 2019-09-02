extends Node

var gravity = -10

const PlayerScene = preload("res://data/scenes/player.tscn")
const Player = preload("res://src/entities/player.gd")

var game
var players_spawn
var monsters_spawn

var local_player : Player = null

signal player_connected(player_name)
signal player_disconnected(player_name)


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
	emit_signal("player_connected", _name)
	return player

func remove_player(_name):
	players_spawn.get_node(_name).queue_free()
	emit_signal("player_disconnected", _name)

func start_game(local_player_name):
	if local_player_name != null:
		var hud = preload("res://data/scenes/hud.tscn").instance()
		$"/root".add_child(hud)
		connect("player_connected", hud.get_node("margin/view"), "_on_player_connected")
		connect("player_disconnected", hud.get_node("margin/view"), "_on_player_disconnected")

	game = preload("res://data/scenes/game.tscn").instance()
	$"/root".add_child(game)
	players_spawn = game.find_node("player_spawn")
	monsters_spawn = game.find_node("monster_spawn")

	add_monster("Dragon", preload("res://data/scenes/monsters/dragon.tscn"))

	if local_player_name != null:
		# Add local player
		local_player = PlayerScene.instance()
		local_player.set_network_master(networking.unique_id)
		local_player.set_name(local_player_name)
		local_player.inventory.connect("modified", $"/root/hud/margin/view/items", "_on_inventory_modified")
		local_player.connect("hp_changed", $"/root/hud/margin/view/status", "_on_hp_changed")
		local_player.connect("stamina_changed", $"/root/hud/margin/view/status", "_on_stamina_changed")
		# Connect signals BEFORE player._ready
		players_spawn.add_child(local_player)
		emit_signal("player_connected", local_player_name)
		prints(local_player_name, "is local player")

	get_tree().set_current_scene(game)
	return game

func stop_game():
	if game != null:
		game.queue_free()
		game = null
		$"/root/hud".queue_free()
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
