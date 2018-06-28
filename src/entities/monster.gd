extends "entity.gd"

export (int, -100, 100) var strength  = 0

export (int, -100, 100) var fire      = 0
export (int, -100, 100) var water     = 0
export (int, -100, 100) var ice       = 0
export (int, -100, 100) var thunder   = 0
export (int, -100, 100) var dragon    = 0
export (int, -100, 100) var poison    = 0
export (int, -100, 100) var paralysis = 0

const SPEED = 5

var weakness = {}
var players = []
var random_target
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
	$collision.disabled = true
	audio(preload("res://data/sounds/dragon-roar.wav"))
	call_deferred("set_script", preload("res://src/interact/monster drop.gd"))

func sort_by_distance(a, b):
	var dist_a = (get_global_transform().origin - a.get_global_transform().origin).length()
	var dist_b = (get_global_transform().origin - b.get_global_transform().origin).length()
	return dist_a < dist_b

func _ready():
	var server = not get_tree().has_network_peer() or is_network_master()
	set_physics_process(server)
	if server:
		set_pause_mode(Node.PAUSE_MODE_PROCESS)

func _physics_process(delta):
	direction = Vector3()
	var origin = get_pos()
	var vector_to_target

	# Check if target is still a possible target
	if not target_player in players or target_player.dead:
		target_player = null

	# Find new target if there are candidates
	if target_player == null and players.size() != 0:
		players.sort_custom(self, "sort_by_distance")
		for player in players:
			if not player.dead:
				vector_to_target = player.get_pos() - origin
				if get_transform().basis.z.dot(vector_to_target.normalized()) > -0.5:
					target_player = player
					break

	if target_player != null:
		random_target = null
		vector_to_target = target_player.get_pos() - origin
		if not combat:
			combat = true
			$exclamation/animation.play("exclamation")
		if vector_to_target.length() > 7.5:
			direction = vector_to_target.normalized() * SPEED
		else:
			direction = vector_to_target.normalized() * 0.01
			if get_tree().has_network_peer():
				rpc("attack", "attack")
			else:
				attack("attack")
	else:
		combat = false
		if random_target == null or (random_target - Vector3(origin.x, 0, origin.z)).length() < 2:
			random_target = Vector3(rand_range(-100, 100), 0, rand_range(-100, 100))
			prints(get_name(), "is going to", random_target)
		direction = (random_target - origin).normalized() * (SPEED/2)

	move_entity(delta)

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

