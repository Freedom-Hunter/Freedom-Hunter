extends AcceptDialog


func prompt_respawn() -> void:
	popup_centered()
	get_parent().get_viewport().get_camera_3d().set_process_input(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_respawn_confirmed() -> void:
	global.local_player.respawn()
	get_parent().get_viewport().get_camera_3d().set_process_input(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

