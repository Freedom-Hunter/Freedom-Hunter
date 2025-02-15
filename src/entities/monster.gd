# SPDX-FileCopyrightText: 2023 Elia Argentieri
#
# SPDX-License-Identifier: GPL-3.0-or-later

extends "entity.gd"

@export_range(-100, 100) var strength  = 0

@export_range(-100, 100) var fire      = 0
@export_range(-100, 100) var water     = 0
@export_range(-100, 100) var ice       = 0
@export_range(-100, 100) var thunder   = 0
@export_range(-100, 100) var dragon    = 0
@export_range(-100, 100) var poison    = 0
@export_range(-100, 100) var paralysis = 0

@export_range(0, 360, 0.1, "radians_as_degrees") var field_of_view = deg_to_rad(120)


var weakness := {}
var players := []
var random_target: Vector3
var target_player: Player
var combat := false
var pointing := false
@onready var nav: NavigationAgent3D = $NavigationAgent3D
@onready var space_state := get_world_3d().get_direct_space_state()
var old_target_origin: Vector3
var red_material := StandardMaterial3D.new()
var last_damage := 0


func _init():
	red_material.albedo_color = Color.RED
	hp = 500
	hp_max = 500
	hp_regenerable = 500
	interpolation_factor = 10
	attack_speed = 0

	weakness = {
		"fire":      fire,
		"water":     water,
		"ice":       ice,
		"thunder":   thunder,
		"dragon":    dragon,
		"poison":    poison,
		"paralysis": paralysis
	}


func _ready():
	super()
	set_physics_process(false)
	call_deferred("setup_monster")


func setup_monster():
	var singleplayer_or_server := not multiplayer.has_multiplayer_peer() or is_multiplayer_authority()
	await NavigationServer3D.map_changed
	set_physics_process(singleplayer_or_server)
	if multiplayer.has_multiplayer_peer() and is_multiplayer_authority():
		set_process_mode(Node.PROCESS_MODE_ALWAYS)
	if singleplayer_or_server:
		call_deferred("new_random_target")


# @override from entity.gd
@rpc("any_peer", "call_local") func died():
	super.died()
	set_physics_process(false)
	$fire.hide()
	$interact.add_to_group("interact")
	$view.disconnect("body_entered", _on_view_body_entered)
	$view.disconnect("body_exited", _on_view_body_exited)
	call_deferred("set_script", preload("res://src/interact/monster drop.gd"))


func new_random_target():
	random_target = Vector3(randf_range(-100, 100), 0, randf_range(-100, 100))
	set_navigation_target(random_target)
	prints(get_name(), "is going to", random_target)


func set_navigation_target(target: Vector3):
	prints(name, "has a new target:", target)
	nav.target_position = target
	old_target_origin = target


func follow_path():
	$fire/RayCast3D.enabled = false
	if not nav.is_navigation_finished():
		var to_target := nav.get_next_path_position() - global_position
		direction = to_target.normalized()


func check_target():
	# Check if target is still a possible target
	if target_player.is_dead():
		print("%s didn't let %s escape. I told you!" % [name, target_player.name])
		target_player = null
		players.erase(target_player)
	elif not target_player in players:
		print("%s let %s escape. This time..." % [name, target_player.name])
		target_player = null


func cast_ray(from: Vector3, to: Vector3) -> Dictionary:
	var query = PhysicsRayQueryParameters3D.new()
	query.from = from
	query.to = to
	return space_state.intersect_ray(query)


func line_of_sight(vector: Vector3) -> Dictionary:
	var origin := global_transform.origin
	var eyes: Vector3 = $eyes.global_transform.origin
	var direction := (vector - origin).normalized()
	var angle := global_transform.basis.z.angle_to(direction)
	if angle < field_of_view:
		return cast_ray(eyes, vector)
	return {}


func check_fire_collision():
	$fire/RayCast3D.enabled = true
	var to_target := target_player.global_position - global_position
	if $AnimationTree["parameters/conditions/attacking"] and to_target.length() < 5:
		if $fire/RayCast3D.is_colliding() and $fire/RayCast3D.get_collider() == target_player:
			if Time.get_ticks_msec() - last_damage > 1000:
				print_debug("collided with", target_player.name)
				target_player.damage(10, 0.3, "fire")
				last_damage = Time.get_ticks_msec()


func find_new_target():
	# Find new target if there are candidates
	var min_distance: float = INF

	for player in players:
		if not player.is_dead():
			var ray := line_of_sight(player.global_position)
			if not ray.is_empty() and ray["collider"] == player:
				var target_distance: float = (player.global_position - global_position).length()
				if target_distance < min_distance:
					target_player = player
					min_distance = target_distance

	if target_player != null:
		# Found a prey.
		set_navigation_target(target_player.global_transform.origin)


func hunt_target():
	if not combat:
		prints(name, "exclamation")
		combat = true
		$exclamation/AnimationPlayer.play("exclamation")

	var to_target := target_player.global_position - global_position
	var distance_from_target = to_target.length()
	if $AnimationTree["parameters/conditions/attacking"]:
		direction = to_target.normalized()
		check_fire_collision()
	elif distance_from_target > 10:
		run()
		follow_path()
	elif distance_from_target > 5:
		walk()
		follow_path()
	else:
		attack("attack")
		direction = to_target.normalized()

	if distance_from_target > 5 and nav.is_navigation_finished():
		if not nav.is_target_reachable():
			# Can't reach the prey?
			if not pointing:
				prints(name, "pointing at not reachable", target_player.name)
				pointing = true
			direction = to_target.normalized()
			stop()
		else:
			pointing = false
	else:
		pointing = false

	if target_player and old_target_origin.distance_to(target_player.global_position) > 1:
		# Prey is trying to escape. Need a new path
		# This avoids to recompute a new path on every frame. Do it only when needed.
		set_navigation_target(target_player.global_transform.origin)


func scout():
	# Walk around randomly, scouting the area
	combat = false
	walk()
	follow_path()
	if nav.is_navigation_finished():
		print("scout done")
		new_random_target()


func _physics_process(delta: float):
	direction = Vector3()

	if target_player != null:
		check_target()
	if target_player == null:
		find_new_target()
	if target_player != null:
		hunt_target()
	else:
		scout()

	nav.get_next_path_position()

	move_entity(delta)


func damage(dmg, reg, element=null, weapon=null, entity=null):
	super.damage(dmg, reg, element, weapon, entity)
	if entity != null and entity.is_in_group("player"):
		if not entity in players:
			players.push_front(entity)
		target_player = entity


func _on_view_body_entered(body: Node):
	if body.is_in_group("player"):
		if not body.is_dead() and not body in players:
			players.push_front(body)
			prints(body.name, "inside", name, "view radius")


func _on_view_body_exited(body: Node):
	if body.is_in_group("player"):
		players.erase(body)
		prints(body.name, "exited", name, "view radius")
