extends Control

onready var global = get_node("/root/global")
onready var networking = get_node("/root/networking")

onready var inventory = get_node("inventory")

var camera_node
var notify_queue = []

func init():
	camera_node = get_viewport().get_camera()

	# Get interact keys
	var keys = InputMap.get_action_list("player_interact")
	var string = ""
	for key in keys:
		string += OS.get_scancode_string(key.scancode) + ","
	string[-1] = ""
	get_node("action").set_text(string)

	update_items()
	global.local_player.inventory.connect("modified", self, "update_items")

func _input(event):
	if get_tree().has_network_peer():
		if event.is_action_pressed("players_list"):
			$players_list.show()
		elif event.is_action_released("players_list"):
			$players_list.hide()
	if event.is_action_released("player_inventory"):
		if inventory.is_visible():
			close_inventories()
		else:
			open_inventories([global.local_player.inventory])

func _physics_process(delta):
	update_values()
	show_interact()
	update_names()
	update_debug()
	if notify_queue.size() > 0 and not $notification/animation.is_playing():
		play_notify(notify_queue.pop_front())

func update_values():
	$hp.set_value(global.local_player.hp)
	$hp/red_hp.set_value(global.local_player.regenerable_hp)
	$stamina.set_value(global.local_player.stamina)
	$stamina.set_max(global.local_player.max_stamina)
	$stamina.set_size(Vector2(10 * global.local_player.max_stamina, $stamina.get_size()[1]))

func open_inventories(inventories):
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	global.local_player.pause_player()
	for inv in inventories:
		inventory.add_child(inv)
	inventory.popup()
	inventory.connect("popup_hide", self, "close_inventories")

func close_inventories():
	if inventory.is_connected("popup_hide", self, "close_inventories"):
		inventory.disconnect("popup_hide", self, "close_inventories")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	global.local_player.resume_player()
	for child in inventory.get_children():
		if child.get_name() != "quit":
			inventory.remove_child(child)
	inventory.hide()

func update_items():
	var inventory = global.local_player.inventory
	var i = -2
	for child in $items_bar.get_children():
		if child is Panel:
			var item = inventory.get_item(inventory.active_item + i)
			child.get_node("icon").set_texture(item.icon)
			i += 1
	var item = inventory.items[inventory.active_item]
	get_node("items_bar/quantity/label").set_text(str(item.quantity))
	item.set_label_color(get_node("items_bar/quantity/label"))
	get_node("items_bar/name/label").set_text(item.name)

func show_interact():
	var interact = global.local_player.get_nearest_interact()
	if interact != null:
		var pos = interact.get_global_transform().origin + Vector3(0, 1, 0)
		if camera_node.is_position_behind(pos):
			$action.hide()
		else:
			$action.show()
			var action_pos = camera_node.unproject_position(pos)
			$action.set_position(action_pos - ($action.get_size()/2))
	else:
		$action.hide()

func _on_action_pressed():
	global.local_player.interact_with_nearest()

func new_label(text):
	var label = Label.new()
	label.set_name(text)
	label.set_text(text)
	return label

func player_connected(player_name):
	$names.add_child(new_label(player_name))
	$players_list.add_child(new_label(player_name))

func player_disconnected(player_name):
	$names.get_node(player_name).queue_free()
	$players_list.get_node(player_name).queue_free()

func update_names():
	var camera_pos = global.local_player.camera_node.get_global_transform().origin
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
					label.set_position(pos - Vector2(size.x/2, size.y/2))
	else:
		var label = $names.get_node(global.local_player.get_name())
		var pos = camera_node.unproject_position(global.local_player.get_node("name").get_global_transform().origin)
		var size = label.get_size()
		label.set_position(pos - Vector2(size.x/2, size.y/2))

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
