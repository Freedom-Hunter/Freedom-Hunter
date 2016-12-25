extends "equipment.gd"

onready var sharpness_node = get_node("/root/game/hud/sharpness/fading")

export(int, 0, 100) var red_sharpness    = 0
export(int, 0, 100) var orange_sharpness = 0
export(int, 0, 100) var yellow_sharpness = 0
export(int, 0, 100) var green_sharpness  = 0
export(int, 0, 100) var blue_sharpness   = 0
export(int, 0, 100) var white_sharpness  = 0
export(int, 0, 100) var purple_sharpness = 0

class Sharp:
	var type
	var value
	func _init(t, v):
		type = t
		value = v

var sharpness
var player

func _ready():
	player = get_node("../../../../..")
	assert(player extends preload("res://src/entities/player.gd"))
	sharpness = [
		Sharp.new("purple",	purple_sharpness),
		Sharp.new("white",	white_sharpness),
		Sharp.new("blue",	blue_sharpness),
		Sharp.new("green",	green_sharpness),
		Sharp.new("yellow",	yellow_sharpness),
		Sharp.new("orange",	orange_sharpness),
		Sharp.new("red",	red_sharpness)
	]
	for s in sharpness:
		if s.value == null: # export bug
			s.value = 0
		if s.value > 0:
			sharpness_node.play(s.type)
			return
	sharpness_node.play("red")

func update_sharpness():
	var anim = sharpness_node.get_current_animation()
	for s in sharpness:
		if s.value > 0:
			s.value -= 1
			if s.value <= 0:
				s.value = 0
				break
			else:
				return
	for s in sharpness:
		if s.value > 0:
			if anim != s.type:
				sharpness_node.play(s.type)
				break

func get_weapon_damage(monster):
	var damage = damage
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
