extends "equipment.gd"

onready var sharpening_node = get_node("/root/game/hud/sharpening/blinking")

export (int, 2000) var attack = 100
# red sharpening is not in list because it is default value
var sharpening_type = ["purple", "white", "blue", "green", "yellow", "orange"]
var sharpening = [1, 1, 1, 1, 1, 1]


func _ready():
	for i in range(sharpening_type.size()):
		if sharpening[i] > 0:
			sharpening_node.play(sharpening_type[i])
			print(sharpening_type[i])
			return
	sharpening_node.play("red")

func hit():
	var anim = sharpening_node.get_current_animation()
	print(sharpening)
	for i in range(sharpening_type.size()):
		if sharpening[i] > 0:
			sharpening[i] -= 1
			if sharpening[i] == 0:
				if i == sharpening.size()-1:
					break
				sharpening_node.play(sharpening_type[i+1])
			return
	if anim != "red":
		sharpening_node.play("red")

func get_weapon_damage(monster):
	var damage = attack
	for element in elements:
		if element in monster.weakness:
			damage += elements[element] * monster.weakness[element]
	return damage

func _on_sword_body_enter(body):
	if body != global.local_player and body extends preload("res://src/entities/entity.gd"):
		if global.local_player.weapon_animation.is_playing():
			body.damage(get_weapon_damage(body), 0.0)
			hit()