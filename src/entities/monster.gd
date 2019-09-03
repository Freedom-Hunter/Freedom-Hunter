extends "entity.gd"

export (int, -100, 100) var strength  = 0

export (int, -100, 100) var fire      = 0
export (int, -100, 100) var water     = 0
export (int, -100, 100) var ice       = 0
export (int, -100, 100) var thunder   = 0
export (int, -100, 100) var dragon    = 0
export (int, -100, 100) var poison    = 0
export (int, -100, 100) var paralysis = 0

var weakness = {}
var players = []
var random_target: Vector3
var target_player
var combat = false
onready var nav: Navigation = get_node("../../..")
var path: Array = []
var path_index: int = 0
var old_target_origin: Vector3


func _init():
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
	var singleplayer_or_server = not get_tree().has_network_peer() or is_network_master()
	set_physics_process(singleplayer_or_server)
	if get_tree().has_network_peer() and is_network_master():
		set_pause_mode(Node.PAUSE_MODE_PROCESS)
	if singleplayer_or_server:
		new_random_target()


# @override from entity.gd
sync func died():
	.died()
	set_physics_process(false)
	animation_node.play("death")
	$fire.hide()
	$interact.add_to_group("interact")
	$view.disconnect("body_entered", self, "_on_view_body_entered")
	$view.disconnect("body_exited", self, "_on_view_body_exited")
	animation_node.disconnect("animation_finished", self, "_on_animation_finished")
	call_deferred("set_script", preload("res://src/interact/monster drop.gd"))


func new_random_target():
	random_target = Vector3(rand_range(-100, 100), 0, rand_range(-100, 100))
	set_navigation_target(random_target)
	prints(get_name(), "is going to", random_target)


func set_navigation_target(target: Vector3, debug=false):
	path_index = 0
	path = nav.get_simple_path(global_transform.origin, target)
	old_target_origin = target

	if debug:
		prints("New path", path)
		var path_m = nav.get_node("path")
		if path_m != null:
			path_m.name = "path.old"
			path_m.queue_free()
		path_m = Spatial.new()
		path_m.name = "path"
		nav.add_child(path_m)
		for i in range(0, path.size()):
			var mesh = MeshInstance.new()
			mesh.mesh = SphereMesh.new()
			mesh.mesh.radius = i * 0.05
			mesh.mesh.height = mesh.mesh.radius * 2
			mesh.transform.origin = path[i]
			path_m.add_child(mesh)


func follow_path():
	var origin = global_transform.origin
	var to_target = path[path_index] - origin
	while to_target.length() < 1 and path_index < path.size():
		path_index += 1
		if path_index < path.size():
			to_target = path[path_index] - origin

	direction = to_target.normalized()


func _physics_process(delta):
	direction = Vector3()
	var origin: Vector3 = global_transform.origin

	if target_player != null:
		# Check if target is still a possible target
		if not target_player in players:
			print("%s let %s escape. This time..." % [name, target_player.name])
			target_player = null
		elif target_player.dead:
			print("%s didn't let %s escape. I told you!" % [name, target_player.name])
			target_player = null
			players.remove(target_player)

	# Find new target if there are candidates
	var min_distance: float = INF
	if target_player == null:
		for player in players:
			if not player.dead:
				var target_direction = (player.global_transform.origin - origin).normalized()
				if global_transform.basis.z.dot(target_direction) > cos(2*PI/3):
					var target_distance = target_direction.length()
					if target_distance < min_distance:
						target_player = player
						min_distance = target_distance
		if target_player != null:
			# Found a prey.
			set_navigation_target(target_player.global_transform.origin)

	if target_player != null:
		if not combat:
			combat = true
			$exclamation/animation.play("exclamation")

		var to_target: Vector3 = target_player.global_transform.origin - origin
		var distance_from_target = to_target.length()
		if attacking:
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

		if path_index >= path.size():
			# Can't reach the prey?
			path_index = path.size() - 1
			direction = to_target.normalized()
			stop()

		if old_target_origin.distance_to(target_player.global_transform.origin) > 1:
			# Prey is trying to escape. Need a new path
			set_navigation_target(target_player.global_transform.origin)
	else:
		# No prey found. Scout the area.
		combat = false
		walk()
		follow_path()
		if path_index >= path.size():
			new_random_target()

	move_entity(delta)


func damage(dmg, reg, weapon=null, entity=null):
	.damage(dmg, reg, weapon, entity)
	if entity != null and entity.is_in_group("player"):
		if not entity in players:
			players.push_front(entity)
		target_player = entity


func _on_view_body_entered(body):
	if body.is_in_group("player"):
		if not body.dead and not body in players:
			players.push_front(body)


func _on_view_body_exited( body ):
	if body.is_in_group("player"):
		players.erase(body)
