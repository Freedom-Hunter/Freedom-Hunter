extends Popup


func _input(event: InputEvent) -> void:
	if event.is_action_released("player_inventory"):
		if is_visible():
			close_inventories()
		else:
			open_inventories([global.local_player.inventory])


func open_inventories(inventories) -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	global.local_player.pause_player()
	get_viewport().get_camera_3d().set_process_input(false)
	for inv in inventories:
		add_child(inv)
	popup()
	popup_hide.connect(close_inventories, CONNECT_ONE_SHOT)


func close_inventories() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	global.local_player.resume_player()
	get_viewport().get_camera_3d().set_process_input(true)
	for child in get_children():
		if child.get_name() != "quit":
			remove_child(child)
	hide()

