
extends Control

const CONF_FILE = "user://multiplayer.conf"

var config

func _ready():
	set_process_input(true)

	config = ConfigFile.new()
	var err = config.load(CONF_FILE)
	if err == OK:
		load_client_config()
		load_server_config()
	else:
		print("Error %s while loading config file." % err)

func _input(event):
	if event.is_action_pressed("ui_cancel") and not get_node("..").mode_node.is_visible():
		networking.stop()
		hide()
		get_node("..").mode_node.show()
		accept_event()

func load_client_config():
	if config.has_section("client"):
		var input = get_node("client/input")
		input.get_node("host").set_text(config.get_value("client", "host", "127.0.0.1"))
		input.get_node("port").set_text(config.get_value("client", "port", "30500"))
		input.get_node("username").set_text(config.get_value("client", "username", ""))

func load_server_config():
	if config.has_section("server"):
		var input = get_node("server/input")
		input.get_node("port").set_text(config.get_value("server", "port", "30500"))
		input.get_node("username").set_text(config.get_value("server", "username", ""))

func save_client_config(username, port, host):
	config.set_value("client", "username", username)
	config.set_value("client", "port", port)
	config.set_value("client", "host", host)
	var err = config.save(CONF_FILE)
	if err != OK:
		print("Error %s while saving configuration file." % err)

func save_server_config(username, port):
	config.set_value("server", "username", username)
	config.set_value("server", "port", port)
	var err = config.save(CONF_FILE)
	if err != OK:
		print("Error %s while saving configuration file." % err)

func _on_start_pressed():
	# Server
	var port = get_node("server/input/port").get_text()
	var username = get_node("server/input/username").get_text().strip_edges()
	if port.is_valid_integer() and username.length() > 0:
		print("Listen on port ", port)
		save_server_config(username, port)
		networking.server_start(int(port), username)
		get_parent().queue_free()
	else:
		print("La porta %s non è valida!" % port)

func _on_connect_pressed():
	# Client
	var port = get_node("client/input/port").get_text()
	var host = get_node("client/input/host").get_text()
	var username = get_node("client/input/username").get_text().strip_edges()

	if port.is_valid_integer() and username.length() > 0:
		save_client_config(username, port, host)
		networking.client_start(host, int(port), username)
		get_parent().queue_free()
