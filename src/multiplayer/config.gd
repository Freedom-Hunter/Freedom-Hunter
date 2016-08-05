
extends Control

const SERVER_CONF = "user://server.conf"
const CLIENT_CONF = "user://client.conf"

func _ready():
	set_process_input(true)
	load_config(SERVER_CONF, "server")
	load_config(CLIENT_CONF, "client")

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		networking.close()
		hide()
		get_node("..").mode_node.show()
		accept_event()

func load_config(path, type):
	var f = File.new()
	if f.file_exists(path):
		f.open(path, f.READ)
		var conf = f.get_var()
		for k in conf:
			get_node(type + "/input").get_node(k).set_text(conf[k])

func save(path, conf):
	var f = File.new()
	f.open(path, f.WRITE)
	f.store_var(conf)
	f.close()

func save_client_config(username, port, host):
	save(CLIENT_CONF, {'username': username, 'port': port, 'host': host})

func save_server_config(username, port):
	save(SERVER_CONF, {'username': username, 'port': port})

func _on_start_pressed():
	# Server
	var port = get_node("server/input/port").get_text()
	var username = get_node("server/input/username").get_text().strip_edges()
	if port.is_valid_integer() and username.length() > 0:
		print("Listen on port ", port)
		save_server_config(username, port)
		networking.server_start(int(port), username)
		global.start_game(username)
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
		global.start_game(username)
		get_parent().queue_free()
