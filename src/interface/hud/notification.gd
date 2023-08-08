# SPDX-FileCopyrightText: 2023 Elia Argentieri
#
# SPDX-License-Identifier: GPL-3.0-or-later

extends Panel


var notify_queue := []


func _ready():
	pass


func play_notify(text: String) -> Signal:
	$text.text = text
	$animation.play("show")
	return $animation.animation_finished


func notify(text) -> void:
	notify_queue.append(text)


func _process(delta: float):
	if notify_queue.size() > 0 and not $animation.is_playing():
		await play_notify(notify_queue.pop_front())
