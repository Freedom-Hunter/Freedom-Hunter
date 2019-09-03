extends Control

onready var global = get_node("/root/global")
onready var networking = get_node("/root/networking")

var notify_queue = []


func _ready():
	# Get interact keys
	var keys = InputMap.get_action_list("player_interact")
	var string = ""
	for key in keys:
		string += OS.get_scancode_string(key.scancode) + ","
	string[-1] = ""
	$action.set_text(string)


func _input(event):
	if get_tree().has_network_peer():
		if event.is_action_pressed("players_list"):
			$players_list.show()
		elif event.is_action_released("players_list"):
			$players_list.hide()
	if event.is_action_released("player_inventory"):
		if $inventory.is_visible():
			close_inventories()
		else:
			open_inventories([global.local_player.inventory])


func _physics_process(delta):
	show_interact()
	update_names()
	update_debug()
	if notify_queue.size() > 0 and not $notification/animation.is_playing():
		play_notify(notify_queue.pop_front())


func open_inventories(inventories):
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	global.local_player.pause_player()
	get_viewport().get_camera().set_process_input(false)
	for inv in inventories:
		$inventory.add_child(inv)
	$inventory.popup()
	$inventory.connect("popup_hide", self, "close_inventories", [], CONNECT_ONESHOT)


func close_inventories():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	global.local_player.resume_player()
	get_viewport().get_camera().set_process_input(true)
	for child in $inventory.get_children():
		if child.get_name() != "quit":
			$inventory.remove_child(child)
	$inventory.hide()


func show_interact():
	var camera_node = get_viewport().get_camera()
	var interact = global.local_player.get_nearest_interact()
	if interact != null:
		var pos = interact.get_global_transform().origin + Vector3.UP
		if camera_node.is_position_behind(pos):
			$action.hide()
		else:
			var action_pos = camera_node.unproject_position(pos)
			$action.set_position(action_pos - ($action.get_size()/2))
			$action.show()
	else:
		$action.hide()


func new_label(text):
	var label = Label.new()
	label.set_name(text)
	label.set_text(text)
	return label


func _on_player_connected(player_name):
	prints("hud:", player_name, "connected")
	$names.add_child(new_label(player_name))
	$players_list.add_child(new_label(player_name))


func _on_player_disconnected(player_name):
	prints("hud:", player_name, "disconnected")
	$names.get_node(player_name).queue_free()
	$players_list.get_node(player_name).queue_free()


func update_names():
	var camera_node = get_viewport().get_camera()
	var camera_pos = camera_node.get_global_transform().origin
	var space_state = get_node("/root/game").get_world().get_direct_space_state()
	if get_tree().has_network_peer():
		for player in networking.get_players():
			var _name = player.get_name()
			var player_pos = player.get_node("name").get_global_transform().origin
			var label = $names.get_node(_name)
			if camera_node.is_position_behind(player_pos):
				label.hide()
			else:
				# use global coordinates, not local to node
				var result = space_state.intersect_ray(camera_pos, player_pos, networking.get_players())
				if not result.empty():
					label.hide()
				else:
					label.show()
					var pos = camera_node.unproject_position(player_pos)
					var size = label.get_size()
					label.rect_global_position = pos - Vector2(size.x/2, size.y/2)
	else:
		var label = $names.get_node(global.local_player.get_name())
		var pos = camera_node.unproject_position(global.local_player.get_node("name").get_global_transform().origin)
		var size = label.get_size()
		label.rect_global_position = pos - Vector2(size.x/2, size.y/2)


func update_debug():
	var pos = global.local_player.get_translation()
	var out = "POS: %.2f %.2f %.2f" % [pos.x, pos.y, pos.z]
	if not networking.is_client_connected():
		out += "\nClient is not connected!"
	$debug.text = out


func play_notify(text):
	$notification/text.text = text
	$notification/animation.play("show")
	yield($notification/animation, "animation_finished")


func notify(text):
	notify_queue.append(text)


func prompt_respawn():
	$respawn.popup_centered()
	get_viewport().get_camera().set_process_input(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_respawn_confirmed():
	global.local_player.respawn()
	get_viewport().get_camera().set_process_input(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
