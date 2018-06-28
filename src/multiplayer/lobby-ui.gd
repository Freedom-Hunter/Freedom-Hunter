
extends Control

const CONF_FILE = "user://multiplayer.conf"

onready var config = ConfigFile.new()
onready var lobby_grid = get_node("lobby/scroll/grid")
onready var client_port = get_node("direct/vbox/client/input/port")
onready var client_host = get_node("direct/vbox/client/input/host")
onready var server_port = get_node("direct/vbox/server/input/port")
onready var server_host = get_node("direct/vbox/server/input/host")
onready var username_node = get_node("header/vbox/input/username")
onready var server_start = get_node("direct/vbox/server/start")
onready var client_connect = get_node("direct/vbox/client/connect")
onready var announce_node = get_node("direct/vbox/server/announce")

func show():
	.show()
	OS.set_window_title("Freedom Hunter Multiplayer Lobby")
	var err = config.load(CONF_FILE)
	if err == OK:
		load_config()
	else:
		print("Error %s occurred while loading config file." % err)
	networking.init_lobby()
	request_servers_list()
	server_validate_input()
	client_validate_input()
	$lobby/refresh.start()
	set_process_input(true)

func hide():
	.hide()
	$"../mode".show()
	OS.set_window_title("Freedom Hunter")
	$lobby/refresh.stop()
	set_process_input(false)

func report_error(message):
	$error_dialog.dialog_text = message
	$error_dialog.popup_centered()

func is_valid_port(port):
	var port_int = int(port)
	return port.is_valid_integer() and port_int > 0 and port_int < 65535

func is_valid_host(host):
	return host.length() > 0

func get_valid_username():
	var username = username_node.get_text().strip_edges()
	if username.length() > 0:
		return username
	print("Invalid username")

func get_valid_server_port():
	var port = server_port.get_text().strip_edges()
	if is_valid_port(port):
		return int(port)
	print("Invalid server port")

func get_valid_server_host():
	var host = server_host.get_text().strip_edges()
	var announce = announce_node.is_pressed()
	if announce and is_valid_host(host):
		return host
	if not announce:
		return ""
	print("Invalid server host")

func server_validate_input(signal_args=null):
	var valid = get_valid_username() != null and get_valid_server_host() != null and get_valid_server_port() != null
	server_start.set_disabled(not valid)

func get_valid_client_port():
	var port = client_port.get_text().strip_edges()
	if is_valid_port(port):
		return int(port)
	print("Invalid client port")

func get_valid_client_host():
	var host = client_host.get_text().strip_edges()
	if is_valid_host(host):
		return host
	print("Invalid client host")

func client_validate_input(signal_args=null):
	var valid = get_valid_username() != null and get_valid_client_host() != null and get_valid_client_port() != null
	client_connect.set_disabled(not valid)

func request_servers_list():  # called every 10 seconds by refresh timer
	networking.lobby.servers_list(self, "_on_servers_list_received")
	if $lobby/refresh.is_stopped():
		$lobby/refresh.start()

func _on_servers_list_received(result, response_code, headers, body):
	networking.lobby.http.disconnect("request_completed", self, "_on_servers_list_received")
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		report_error("Can't retrieve servers list")
		$lobby/refresh.stop()
	else:
		var servers = str2var(body.get_string_from_utf8())
		if typeof(servers) == TYPE_ARRAY:
			update_servers_list(servers)
		else:
			report_error("Lobby server returned garbage.")
			$lobby/refresh.stop()

func update_servers_list(servers):
	var fields = ['hostname', 'port', 'connected_players', 'max_players']
	var disable = get_valid_username() == null

	for child in lobby_grid.get_children():
		if child.get_name().split('|').size() > 1:
			child.free()

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

func _on_lobby_connect_pressed(button):
	var server_id = button.get_name().split('|')[1]
	var host = button.get_node("../hostname|" + server_id).get_text()
	var port = button.get_node("../port|" + server_id).get_text()
	var username = get_valid_username()
	networking.client_start(host, int(port), username, server_id)
	get_parent().queue_free()

func _on_username_text_changed(text):
	if text.length() < 2:
		var disable = get_valid_username() == null
		for child in lobby_grid.get_children():
			if child is Button and child.get_name().split('|').size() > 1:
				child.set_disabled(disable)
		server_validate_input()
		client_validate_input()

func load_config():
	if config.has_section("client"):
		client_host.set_text(config.get_value("client", "host", "127.0.0.1"))
		client_port.set_text(config.get_value("client", "port", "30500"))
	if config.has_section("server"):
		server_host.set_text(config.get_value("server", "host", ""))
		server_port.set_text(config.get_value("server", "port", "30500"))
		announce_node.set_pressed(config.get_value("server", "announce", true))
	if config.has_section("global"):
		username_node.set_text(config.get_value("global", "username", ""))

func save_config():
	if get_valid_username() != null:
		config.set_value("global", "username", get_valid_username())
	if is_valid_port(client_port.get_text()):
		config.set_value("client", "port", client_port.get_text())
	if is_valid_host(client_host.get_text()):
		config.set_value("client", "host", client_host.get_text())
	if is_valid_port(server_port.get_text()):
		config.set_value("server", "port", server_port.get_text())
	if is_valid_host(server_host.get_text()):
		config.set_value("server", "host", server_host.get_text())
	config.set_value("server", "announce", announce_node.is_pressed())
	var err = config.save(CONF_FILE)
	if err != OK:
		printerr("Error %s occurred while saving configuration file." % err)

func _input(event):
	if event.is_action_pressed("ui_cancel") and not get_node("../mode").is_visible():
		hide()
		accept_event()

func _on_start_pressed():
	# Server
	save_config()
	if announce_node.is_pressed():
		networking.server_start(get_valid_server_port(), get_valid_username(), get_valid_server_host())
	else:
		networking.server_start(get_valid_server_port(), get_valid_username())
	get_parent().queue_free()

func _on_connect_pressed():
	# Client
	save_config()
	var ip = get_valid_client_host()
	var port = get_valid_client_port()
	networking.client_start(ip, port, get_valid_username())
	for child in get_children():
		child.hide()
	$connecting.popup_centered()
	$lobby/refresh.stop()
	get_tree().connect("connection_failed", self, "_connection_failed", [ip, port])
	get_tree().connect("connected_to_server", self, "_connected_to_server")

func _connection_failed(ip, port):
	for child in get_children():
		child.show()
	$connecting.hide()
	$lobby/refresh.start()
	report_error("Connection to %s:%s failed" % [ip, port])
	get_tree().disconnect("connection_failed", self, "_connection_failed")

func _connected_to_server():
	get_parent().queue_free()
