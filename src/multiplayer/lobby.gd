
extends Control

const CONF_FILE = "user://multiplayer.conf"

onready var config = ConfigFile.new()
onready var lobby_grid = get_node("lobby/grid")
onready var client_port = get_node("direct/vbox/client/input/port")
onready var client_host = get_node("direct/vbox/client/input/host")
onready var server_port = get_node("direct/vbox/server/input/port")
onready var username_node = get_node("header/vbox/input/username")
onready var server_start = get_node("direct/vbox/server/start")
onready var client_connect = get_node("direct/vbox/client/connect")
onready var announce_node = get_node("direct/vbox/server/announce")

func _ready():
	OS.set_window_title("Freedom Hunter Lobby")

	var err = config.load(CONF_FILE)
	if err == OK:
		load_config()
	else:
		print("Error %s occurred while loading config file." % err)
	update_servers_list()
	set_process_input(true)

func update_servers_list():
	var fields = ['hostname', 'port', 'connected_players', 'max_players']
	var servers = networking.lobby_servers_list()
	var disable = username_node.get_text().length() == 0

	for child in lobby_grid.get_children():
		if child.get_name().split('|').size() > 1:
			child.queue_free()

	if typeof(servers) == TYPE_ARRAY:
		for server in servers:
			for field in fields:
				var l = Label.new()
				l.set_name(str(field, '|', server.id))
				l.set_text(str(server[field]))
				lobby_grid.add_child(l)
			var connect_btn = Button.new()
			connect_btn.set_text("Connect")
			connect_btn.set_name(str("connect|", server.id))
			connect_btn.set_disabled(disable)
			lobby_grid.add_child(connect_btn)
			connect_btn.connect("pressed", self, "_on_lobby_connect_pressed", [connect_btn])
	server_start.set_disabled(disable)
	client_connect.set_disabled(disable)

func _exit_tree():
	OS.set_window_title("Freedom Hunter")

func _on_lobby_connect_pressed(button):
	print("%s was pressed" % button)
	var suffix = button.get_name().split('|')[1]
	var host = button.get_node("../hostname|" + suffix).get_text()
	var port = button.get_node("../port|" + suffix).get_text()
	var username = get_node("header/vbox/input/username").get_text()
	print("Connect to %s:%s as %s" % [host, port, username])
	networking.lobby_register_player(username, suffix)
	print("Lobby player ID: %s" % networking.lobby_player_id)
	networking.client_start(host, int(port), username)
	get_parent().queue_free()

func _on_username_text_changed(text):
	var disable = text.length() == 0
	for child in lobby_grid.get_children():
		if child extends Button:
			child.set_disabled(disable)
	server_start.set_disabled(disable)
	client_connect.set_disabled(disable)

func _input(event):
	if event.is_action_pressed("ui_cancel") and not get_node("..").mode_node.is_visible():
		networking.stop()
		hide()
		get_node("..").mode_node.show()
		accept_event()

func load_config():
	if config.has_section("client"):
		client_host.set_text(config.get_value("client", "host", "127.0.0.1"))
		client_port.set_text(config.get_value("client", "port", "30500"))
	if config.has_section("server"):
		server_port.set_text(config.get_value("server", "port", "30500"))
	if config.has_section("global"):
		username_node.set_text(config.get_value("global", "username", ""))

func save_config():
	if username_node.get_text().length() > 0:
		config.set_value("global", "username", username_node.get_text())
	if client_port.get_text().length() > 0:
		config.set_value("client", "port", client_port.get_text())
	if client_host.get_text().length() > 0:
		config.set_value("client", "host", client_host.get_text())
	if server_port.get_text().length() > 0:
		config.set_value("server", "port", server_port.get_text())
	var err = config.save(CONF_FILE)
	if err != OK:
		print("Error %s occurred while saving configuration file." % err)

func _on_start_pressed():
	# Server
	var port = server_port.get_text()
	var username = username_node.get_text().strip_edges()
	var announce = announce_node.is_pressed()
	if port.is_valid_integer() and username.length() > 0:
		print("Listen on port ", port)
		save_config()
		networking.server_start(int(port), username, announce)
		get_parent().queue_free()
	else:
		print("La porta %s non è valida!" % port)

func _on_connect_pressed():
	# Client
	var port = client_port.get_text()
	var host = client_host.get_text()
	var username = username_node.get_text().strip_edges()

	if port.is_valid_integer() and username.length() > 0:
		save_config()
		networking.client_start(host, int(port), username)
		get_parent().queue_free()
