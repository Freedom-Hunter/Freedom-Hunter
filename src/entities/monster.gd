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

@export_range(-3.14, 3.14, 0.001, "radians") var field_of_view = deg_to_rad(120)


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
	var singleplayer_or_server := not multiplayer.has_multiplayer_peer() or is_multiplayer_authority()
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
	set_navigation_target(random_target, true)
	prints(get_name(), "is going to", random_target)


func set_navigation_target(target: Vector3, debug=false):
	prints(name, "has a new target:", target)
	nav.target_position = target
	old_target_origin = target

	if debug:
		call_deferred("debug_navigation")


func debug_navigation():
	visualize_path(nav.get_current_navigation_path())


func visualize_path(path: Array):
	var path_m := nav.get_node("path")
	if path_m != null:
		path_m.name = "path.old"
		path_m.queue_free()
	path_m = Node3D.new()
	path_m.name = "path"
	nav.add_child(path_m)
	for i in range(0, path.size()):
		var mesh := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = i * 0.05
		sphere.height = i * 0.05 * 2
		mesh.mesh = sphere
		mesh.transform.origin = path[i]
		path_m.add_child(mesh)
		if i == path.size() - 1:
			mesh.material_override = red_material


func follow_path():
	if not nav.is_navigation_finished():
		var to_target := nav.get_next_path_position() - global_position
		direction = to_target.normalized()


func check_target():
	# Check if target is still a possible target
	if not target_player in players:
		print("%s let %s escape. This time..." % [name, target_player.name])
		target_player = null
	elif target_player.is_dead():
		print("%s didn't let %s escape. I told you!" % [name, target_player.name])
		target_player = null
		players.erase(target_player)


func line_of_sight(vector: Vector3) -> Dictionary:
	var origin := global_transform.origin
	var eyes: Vector3 = $eyes.global_transform.origin
	var direction := (vector - origin).normalized()
	var angle := global_transform.basis.z.angle_to(direction)
	if angle < field_of_view:
		var query = PhysicsRayQueryParameters3D.new()
		query.from = eyes
		query.to = vector
		return space_state.intersect_ray(query)
	return {}


func find_new_target():
	# Find new target if there are candidates
	var origin: Vector3 = global_transform.origin
	var eyes: Vector3 = $eyes.global_transform.origin
	var min_distance: float = INF
	var space_state: PhysicsDirectSpaceState3D = get_node("/root/game").get_world_3d().get_direct_space_state()

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
		set_navigation_target(target_player.global_transform.origin, true)


func hunt_target():
	if not combat:
		prints(name, "exclamation")
		combat = true
		$exclamation/AnimationPlayer.play("exclamation")

	var to_target := target_player.global_position - global_position
	var distance_from_target = to_target.length()
	if $AnimationTree["parameters/conditions/attacking"]:
		direction = to_target.normalized()
	elif distance_from_target > 10:
		run()
		follow_path()
	elif distance_from_target > 5:
		walk()
		follow_path()
	else:
		attack("attack")
		direction = to_target.normalized()

	if nav.is_navigation_finished():
		if not nav.is_target_reachable():
			# Can't reach the prey?
			if not pointing:
				prints(name, "pointing at not reachable", target_player.name)
				pointing = true
			direction = to_target.normalized()
			stop()
		else:
			prints(name, "gave up on", target_player.name)
			target_player = null
			pointing = false
	else:
		pointing = false

	if target_player and old_target_origin.distance_to(target_player.global_position) > 1:
		# Prey is trying to escape. Need a new path
		# This avoids to recompute a new path on every frame. Do it only when needed.
		set_navigation_target(target_player.global_transform.origin, true)


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


func damage(dmg, reg, weapon=null, entity=null):
	super.damage(dmg, reg, weapon, entity)
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

