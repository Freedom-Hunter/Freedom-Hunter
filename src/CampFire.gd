# SPDX-FileCopyrightText: 2023 Elia Argentieri
#
# SPDX-License-Identifier: GPL-3.0-or-later

extends Area3D


func _on_CampFire_body_entered(body):
	if body is Entity:
		var timer = Timer.new()
		timer.name = "burning"
		timer.wait_time = 1.0
		timer.autostart = true
		timer.connect("timeout", Callable(self, "_on_burning_timer_timeout").bind(body))
		body.add_child(timer)


func _on_burning_timer_timeout(body: Entity):
	if body is Entity:
		body.damage(10, 0.3)


func _on_CampFire_body_exited(body):
	if body is Entity:
		body.get_node("burning").queue_free()
