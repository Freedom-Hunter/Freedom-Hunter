class_name GlobalAutoload
extends Node

var gravity = -10

const PlayerScene = preload("res://data/scenes/player/male.tscn")


var game: Node3D
var hud: Control
var players_spawn: Marker3D
var monsters_spawn: Marker3D

var local_player : Player = null

signal player_connected(player_name)
signal player_disconnected(player_name)


static func add_entity(_name, scene, spawn, id=1):
	var entity = scene.instantiate()
	entity.set_multiplayer_authority(id)
	entity.set_name(_name)
	spawn.add_child(entity)
	return entity


func add_monster(_name, scene):
	return self.add_entity(_name, scene, monsters_spawn)


func add_player(_name, id=1, transform=null):
	var player = self.add_entity(_name, PlayerScene, players_spawn, id)
	if id == networking.unique_id:
		prints(_name, "is local player")
		local_player = player
	else:
		prints(_name, "is remote player")
	if transform != null:
		player.transform = transform
	player_connected.emit(_name)
	return player


func remove_player(_name):
	players_spawn.get_node(_name).queue_free()
	emit_signal("player_disconnected", _name)


func start_game(local_player_name):
	if local_player_name != null:
		hud = preload("res://data/scenes/hud.tscn").instantiate()
		$"/root".add_child(hud)

	game = preload("res://data/scenes/game.tscn").instantiate()
	$"/root".add_child(game)
	players_spawn = game.find_child("player_spawn")
	monsters_spawn = game.find_child("monster_spawn")

	add_monster("Dragon", preload("res://data/scenes/monsters/dragon.tscn"))

	if local_player_name != null:
		# Add local player
		local_player = PlayerScene.instantiate()
		local_player.set_multiplayer_authority(networking.unique_id)
		local_player.set_name(local_player_name)
		local_player.inventory.connect("modified", $/root/hud/items._on_inventory_modified)
		
		var potion    = Potion.new("Potion",       preload("res://data/images/items/potion.png"),    10, 20)
		var whetstone = Whetstone.new("Whetstone", preload("res://data/images/items/whetstone.png"), 10, 20)
		var meat      = Meat.new("Meat",           preload("res://data/images/items/meat.png"),      5,  25)
		local_player.inventory.set_items([potion, whetstone, meat], 30)

		local_player.hp_changed.connect($/root/hud/status._on_hp_changed)
		local_player.stamina_changed.connect($/root/hud/status._on_stamina_changed)
		# Connect signals BEFORE player._ready
		players_spawn.add_child(local_player)
		player_connected.emit(local_player_name)
		prints(local_player_name, "is local player")

	get_tree().set_current_scene(game)
	return game


func stop_game():
	if game != null:
		game.queue_free()
		game = null
		$/root/hud.queue_free()
	get_node("/root/networking").stop()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = false
	get_tree().change_scene_to_file("res://data/scenes/main_menu.tscn")


func exit_clean():
	var networking = get_node("/root/networking")
	networking.stop()
	get_tree().quit()


func _notification(what):
	if what == Window.NOTIFICATION_WM_CLOSE_REQUEST:
		exit_clean()


func toggle_fullscreen():
	var win = get_window()
	match win.mode:
		Window.MODE_EXCLUSIVE_FULLSCREEN, Window.MODE_FULLSCREEN:
			win.mode = Window.MODE_WINDOWED
		_:
			win.mode = Window.MODE_EXCLUSIVE_FULLSCREEN


func pause():
	if hud and game:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().paused = true
		hud.get_node("pause_menu").popup_centered()


func unpause():
	if hud and game:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		get_tree().paused = false
		hud.get_node("pause_menu").hide()


func _input(event):
	if event.is_action_pressed("ui_cancel"):
		if not get_tree().paused:
			pause()
		else:
			unpause()
	if event.is_action_pressed("ui_fullscreen"):
		toggle_fullscreen()

