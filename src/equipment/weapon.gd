extends "equipment.gd"

onready var sharpness_node = get_node("/root/game/hud/sharpness/fading")

export (int, 2000) var attack = 10
# red sharpness is not in list because it is default value
var sharpness_type = ["purple", "white", "blue", "green", "yellow", "orange"]
var sharpness = [1, 1, 1, 1, 1, 1]
var player

func _ready():
	for i in range(sharpness_type.size()):
		if sharpness[i] > 0:
			sharpness_node.play(sharpness_type[i])
			return
	sharpness_node.play("red")

func init(_player):
	player = _player

func update_sharpness():
	var anim = sharpness_node.get_current_animation()
	for i in range(sharpness_type.size()):
		if sharpness[i] > 0:
			sharpness[i] -= 1
			if sharpness[i] == 0:
				if i == sharpness.size()-1:
					break
				sharpness_node.play(sharpness_type[i+1])
			return
	if anim != "red":
		sharpness_node.play("red")

func get_weapon_damage(monster):
	var damage = attack
	if not 'weakness' in monster:
		return damage
	for element in elements:
		if element in monster.weakness:
			damage += elements[element] * monster.weakness[element]
	return damage

func _on_sword_body_enter(body):
	if body != player and player.attack_animation_node.is_playing() and body extends preload("res://src/entities/entity.gd"):
		body.damage(get_weapon_damage(body), 0.0)
		if player == global.local_player:
			update_sharpness()
