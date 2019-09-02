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


func _init().(500, 100, 1):
	weakness = {
		"fire":      fire,
		"water":     water,
		"ice":       ice,
		"thunder":   thunder,
		"dragon":    dragon,
		"poison":    poison,
		"paralysis": paralysis
	}

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

func sort_by_distance(a, b):
	var dist_a = global_transform.origin.distance_to(a.global_transform.origin)
	var dist_b = global_transform.origin.distance_to(b.global_transform.origin)
	return dist_a < dist_b

func new_random_target():
	random_target = Vector3(rand_range(-100, 100), 0, rand_range(-100, 100))
	prints(get_name(), "is going to", random_target)

func _ready():
	var singleplayer_or_server = not get_tree().has_network_peer() or is_network_master()
	set_physics_process(singleplayer_or_server)
	if get_tree().has_network_peer() and is_network_master():
		set_pause_mode(Node.PAUSE_MODE_PROCESS)
	if singleplayer_or_server:
		new_random_target()

func _physics_process(delta):
	direction = Vector3()
	var origin = global_transform.origin

	# Check if target is still a possible target
	if not target_player in players or target_player.dead:
		target_player = null

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
		var vector_to_target = target_player.global_transform.origin - origin
		if not combat:
			combat = true
			$exclamation/animation.play("exclamation")
		if vector_to_target.length() > 7.5:
			direction = vector_to_target.normalized()
			run()
		else:
			direction = vector_to_target.normalized()
			attack("attack")
	else:
		combat = false
		var target_distance = random_target.distance_to(Vector3(origin.x, 0, origin.z))
		if target_distance < 2:
			new_random_target()
		direction = (random_target - origin).normalized()

	move_entity(delta)

	$fire.process_material.initial_velocity = velocity.length() + 5

func damage(dmg, reg, weapon=null, entity=null):
	.damage(dmg, reg, weapon, entity)
	if entity != null:
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

