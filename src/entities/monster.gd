extends "entity.gd"

onready var view_node = get_node("view")
onready var animation = get_node("animation")

export (int, FLAGS, "Fire", "Water", "Ice", "Thunder", "Dragon", \
"Poison", "Paralysis") var weakness_type = 0
export var weakness_effect = Array()  # Float value from 0 to 1
export var hardness = IntArray()

const SPEED = 5

var weakness = {}

func init():
	hp = 500
	interpolation_factor = 1
	if networking.is_server() or not networking.multiplayer:
		set_fixed_process(true)

	# It builds a dictionary with the name of the weapon's elements as key
	# and as a value taken from the power of the element
	var j = 0
	for i in range(global.ELEMENTS.size()):
		if int(pow(2, i)) & weakness_type:
			weakness[global.ELEMENTS[i]] = weakness_effect[j]
			j += 1

# @override from entity.gd
func die():
	set_fixed_process(false)
	rotate_z(PI/2)

func attack():
	if not animation.is_playing():
		animation.play("attack")
		if networking.is_server():
			networking.peer.local_monster_attack(get_name())

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
				attack()
	move_entity(delta)