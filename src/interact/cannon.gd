# SPDX-FileCopyrightText: 2023 Elia Argentieri
#
# SPDX-License-Identifier: GPL-3.0-or-later

class_name CannonNode
extends Node3D


var tween: Tween

@onready var ball_spawn: Marker3D = $ball


func _ready():
	#tween.set_ease(Tween.EASE_IN_OUT)
	#tween.set_loops(1)
	#tween.set_parallel(false)
	#tween.set_speed_scale(1)
	#tween.set_trans(Tween.TRANS_LINEAR)
	pass


func interact(player:Player, node):
	match node.name:
		"fire":
			fire_ball_from_inventory(player)
		"clockwise":
			tween_rotate(-15)
		"anticlockwise":
			tween_rotate(15)
		_:
			print_debug("Not a known node")


func fire_ball_from_inventory(player: Player):
	var cannon_ball := player.inventory.find_item_by_name("Cannonball")
	if cannon_ball != null:
		fire(cannon_ball)
		if cannon_ball.quantity <= 0:
			player.inventory.erase_item(cannon_ball)


func fire(cannon_ball: CannonBall, spawn=null):
	if not $animation.is_playing() and tween == null:
		cannon_ball.fire(self, spawn)
		$animation.play("fire")


func tween_rotate(angle, duration=0.5):
	if not $animation.is_playing() and tween == null:
		var initial = rotation_degrees
		var final = initial + Vector3(0, angle, 0)
		tween = create_tween()
		tween.tween_property(self, "rotation_degrees", final, duration)
		tween.tween_callback(func(): self.tween = null)
		tween.play()

