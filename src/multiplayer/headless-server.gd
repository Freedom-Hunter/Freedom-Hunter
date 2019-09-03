# Headless server
# FIXME: completely broken since we switched to Godot's high level multiplayer API

extends SceneTree

var Server = preload("res://src/multiplayer/server.gd")
var global = preload("res://src/global.gd").new()
var networking = preload("res://src/multiplayer/networking.gd").new()

var server


func _init():
	OS.set_iterations_per_second(10)
	global.set_name("global")
	networking.set_name("networking")
	get_root().add_child(global)
	get_root().add_child(networking)
	var port = 30500
	for arg in OS.get_cmdline_args():
		if arg.begins_with("-port="):
			port = int(arg.split("=")[1])
	server = networking.server_start(port)

func _iteration(delta):
	server.process(delta)
