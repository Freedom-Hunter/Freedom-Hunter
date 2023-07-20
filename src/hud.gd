class_name HUD
extends Control

@onready var global: GlobalAutoload = get_node("/root/global")
@onready var networking: NetworkingAutoload = get_node("/root/networking")

var notify_queue := []


func _ready() -> void:
	# Get interact keys
	var keys = InputMap.action_get_events("player_interact")
	var strings: PackedStringArray = []
	for key in keys:
		if key is InputEventKey:
			strings.append(OS.get_keycode_string(key.keycode))
		elif key is InputEventJoypadButton:
			strings.append("Joy" + str(key.button_index))
	$action.set_text(",".join(strings))


func _input(event: InputEvent) -> void:
	if multiplayer.has_multiplayer_peer():
		if event.is_action_pressed("players_list"):
			$players_list.show()
		elif event.is_action_released("players_list"):
			$players_list.hide()
	if event.is_action_released("player_inventory"):
		if $inventory.is_visible():
			close_inventories()
		else:
			open_inventories([global.local_player.inventory])


func _physics_process(_delta) -> void:
	show_interact()
	update_names()
	update_debug()
	if notify_queue.size() > 0 and not $notification/animation.is_playing():
		await play_notify(notify_queue.pop_front())


func open_inventories(inventories) -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	global.local_player.pause_player()
	get_viewport().get_camera_3d().set_process_input(false)
	for inv in inventories:
		$inventory.add_child(inv)
	$inventory.popup()
	$inventory.connect("popup_hide", Callable(self, "close_inventories").bind(), CONNECT_ONE_SHOT)


func close_inventories() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	global.local_player.resume_player()
	get_viewport().get_camera_3d().set_process_input(true)
	for child in $inventory.get_children():
		if child.get_name() != "quit":
			$inventory.remove_child(child)
	$inventory.hide()


func show_interact() -> void:
	var camera_node := get_viewport().get_camera_3d()
	var interact := global.local_player.get_nearest_interact()
	if interact != null:
		var pos := interact.get_global_transform().origin + Vector3.UP
		if camera_node.is_position_behind(pos):
			$action.hide()
		else:
			var action_pos := camera_node.unproject_position(pos)
			$action.set_position(action_pos - ($action.get_size()/2))
			$action.show()
	else:
		$action.hide()


func new_label(text: String) -> Label:
	var label := Label.new()
	label.set_name(text)
	label.set_text(text)
	return label


func _on_player_connected(player_name: String) -> void:
	prints("hud:", player_name, "connected")
	$names.add_child(new_label(player_name))
	$players_list.add_child(new_label(player_name))


func _on_player_disconnected(player_name: String) -> void:
	prints("hud:", player_name, "disconnected")
	$names.get_node(player_name).queue_free()
	$players_list.get_node(player_name).queue_free()


func update_names() -> void:
	var camera_node := get_viewport().get_camera_3d()
	var camera_pos := camera_node.global_position
	var space_state: PhysicsDirectSpaceState3D = get_node("/root/game").get_world_3d().get_direct_space_state()
	if multiplayer.has_multiplayer_peer():
		for player in networking.get_players():
			var _name: String = player.get_name()
			var player_pos: Vector3 = player.get_node("name").global_position
			var label: Label = $names.get_node(NodePath(_name))
			if camera_node.is_position_behind(player_pos):
				label.hide()
			else:
				# use global coordinates, not local to node
				var query := PhysicsRayQueryParameters3D.new()
				query.from = camera_pos
				query.to = player_pos
				query.exclude = networking.get_players()
				var result := space_state.intersect_ray(query)
				if not result.is_empty():
					label.hide()
				else:
					label.show()
					var pos := camera_node.unproject_position(player_pos)
					var label_size := label.get_size()
					label.global_position = pos - label_size / 2
	else:
		var label: Label = $names.get_node(NodePath(global.local_player.get_name()))
		var pos: Vector2 = camera_node.unproject_position(global.local_player.get_node("name").get_global_transform().origin)
		var label_size: Vector2 = label.get_size()
		label.global_position = pos - label_size / 2


func update_debug() -> void:
	var pos := global.local_player.position
	var out := "POS: %.2f %.2f %.2f" % [pos.x, pos.y, pos.z]
	if not networking.is_client_connected():
		out += "\nClient is not connected!"
	$debug.text = out


func play_notify(text) -> Signal:
	$notification/text.text = text
	$notification/animation.play("show")
	return $notification/animation.animation_finished


func notify(text) -> void:
	notify_queue.append(text)


func prompt_respawn() -> void:
	$respawn.popup_centered()
	get_viewport().get_camera_3d().set_process_input(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_respawn_confirmed() -> void:
	global.local_player.respawn()
	get_viewport().get_camera_3d().set_process_input(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
