extends "entity.gd"

onready var view_node = get_node("view")
onready var interact_node = get_node("interact")

export (int, FLAGS, "Fire", "Water", "Ice", "Thunder", "Dragon", \
"Poison", "Paralysis") var weakness_type = 0
export var weakness_effect = Array()  # Float value from 0 to 1
export var hardness = IntArray()

const SPEED = 5

var weakness = {}

func _init().(500, 100, "animation", 1):
	pass

func _ready():
	if networking.is_server() or not networking.multiplayer:
		set_fixed_process(true)

# @override from entity.gd
func die():
	set_fixed_process(false)
	rotate_z(PI/2)
	get_node("fire").hide()
	interact_node.add_to_group("interact")
	set_script(preload("res://src/interact/monster drop.gd"))

func sort_by_distance(a, b):
	var dist_a = (get_global_transform().origin - a.get_global_transform().origin).length()
	var dist_b = (get_global_transform().origin - b.get_global_transform().origin).length()
	return dist_a < dist_b

func get_player():
	var players = view_node.get_overlapping_bodies()
	for i in players:
		if not i.is_in_group("player"):
			players.erase(i)
	if players.size() > 0:
		players.sort_custom(self, "sort_by_distance")
		return players[0]
	return null

func _fixed_process(delta):
	direction = Vector3()
	var origin = get_pos()
	var player = get_player()

	if player != null:
		var distance_from_player = player.get_pos() - origin
		if get_transform().basis.z.dot(distance_from_player.normalized()) > -0.5:
			if distance_from_player.length() > 7.5:
				direction = distance_from_player.normalized() * SPEED
			else:
				direction = distance_from_player.normalized() * 0.01
				if not animation_node.is_playing():
					attack("attack")
	move_entity(delta)
