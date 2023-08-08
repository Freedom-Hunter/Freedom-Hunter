# SPDX-FileCopyrightText: 2023 Elia Argentieri
#
# SPDX-License-Identifier: GPL-3.0-or-later

extends Label


var messages := {}


func add_message(message: String) -> void:
	var ticks := Time.get_ticks_msec()
	if messages[ticks]:
		messages[ticks] += "\n" + message
	else:
		messages[ticks] = message


func _process(delta):
	if visible:
		var pos := global.local_player.position
		text = "POS: %.2f %.2f %.2f" % [pos.x, pos.y, pos.z]
		if not networking.is_client_connected():
			text += "\nClient is not connected!"
		for time in messages:
			if time - Time.get_ticks_msec() > 10000:
				messages.erase(time)
		text += "\n".join(messages.values())

