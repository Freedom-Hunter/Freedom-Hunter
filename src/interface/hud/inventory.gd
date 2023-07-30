extends Popup


func _input(event: InputEvent) -> void:
	if event.is_action_released("player_inventory"):
		close_inventories()


func open_inventories(inventories) -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	global.local_player.pause_player()
	get_parent().get_viewport().get_camera_3d().set_process_input(false)
	for inv in inventories:
		inv.position = Vector2()
		$hbox.add_child(inv)
	popup()
	popup_hide.connect(close_inventories, CONNECT_ONE_SHOT)


func open_player_inventory() -> void:
	open_inventories([global.local_player.inventory])


func close_inventories() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	global.local_player.resume_player()
	get_parent().get_viewport().get_camera_3d().set_process_input(true)
	for child in $hbox.get_children():
		remove_child(child)
	hide()


func _on_quit_pressed():
	close_inventories()


func _on_popup_hide():
	if $hbox.get_children().size() > 0:
		close_inventories()

