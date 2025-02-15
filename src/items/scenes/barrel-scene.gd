# SPDX-FileCopyrightText: 2023 Elia Argentieri
#
# SPDX-License-Identifier: GPL-3.0-or-later

extends RigidBody3D


func _on_timer_timeout():
	$"explosion/animation".play("explode")
	var r = $"explosion/radius".shape.radius
	for body in $"explosion".get_overlapping_bodies():
		if body == self:
			continue
		var d = body.global_transform.origin - global_transform.origin
		if body is Entity:
			var dmg = int((r - d.length()) * 20 + 1)
			body.damage(dmg, 0.1)
		elif body.is_in_group("explosive"):
			var momentum = d.normalized() * (r - d.length()) * mass
			body.apply_central_impulse(momentum)
			if not body.get_node("explosion/animation").is_playing():
				var body_timer: Timer = body.get_node("explosion/timer")
				if body_timer.time_left > 0.5:
					body_timer.stop()
					body_timer.set_wait_time(0.5 - randf_range(0, 0.4))
					body_timer.start()


func _on_animation_finished(_animation):
	queue_free()
