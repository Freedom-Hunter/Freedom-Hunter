# SPDX-FileCopyrightText: 2023 Elia Argentieri
#
# SPDX-License-Identifier: GPL-3.0-or-later

extends Button


func _ready():
	# Get interact keys
	var keys := InputMap.action_get_events("player_interact")
	var strings := []
	for key in keys:
		if key is InputEventKey:
			strings.append(OS.get_keycode_string(key.keycode))
		elif key is InputEventJoypadButton:
			strings.append("Joy" + str(key.button_index))
	text = ",".join(strings)


func _process(delta: float):
	var camera_node := get_viewport().get_camera_3d()
	var interact := global.local_player.get_nearest_interact()
	if interact != null:
		var pos := interact.get_global_transform().origin + Vector3.UP
		if camera_node.is_position_behind(pos):
			hide()
		else:
			var action_pos := camera_node.unproject_position(pos)
			position = action_pos - get_size() / 2
			show()
	else:
		hide()
