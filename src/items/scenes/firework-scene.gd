# SPDX-FileCopyrightText: 2023 Elia Argentieri
#
# SPDX-License-Identifier: GPL-3.0-or-later

class_name FireworkNode
extends RigidBody3D


func launch():
	linear_velocity = Vector3(0, 70, 0)
	linear_velocity.x += randf_range(-20, 20)
	linear_velocity.y += randf_range(-20, 20)
	linear_velocity.z += randf_range(-20, 20)
	$animation.play("launch")
	await get_tree().create_timer(randf_range(4, 5)).timeout
	$animation.play("boom")
	await $animation.animation_finished
	queue_free()
