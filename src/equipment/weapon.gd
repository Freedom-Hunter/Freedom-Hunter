extends "equipment.gd"

const Player = preload("res://src/entities/player.gd")
const Entity = preload("res://src/entities/entity.gd")

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
	var max_val
	func _init(t, v):
		if v == null: # export bug
			v = 0
		type = t
		value = v
		max_val = v

var sharpness
var player

func _ready():
	player = get_node("../../../../..")
	assert(player is Player)
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
		if s.value > 0:
			sharpness_node.play(s.type)
			return

func update_animation():
	var anim = sharpness_node.get_current_animation()
	for s in sharpness:
		if s.value > 0:
			if anim != s.type:
				sharpness_node.play(s.type)
			return
	if anim != "red":
		sharpness_node.play("red")

func blunt(amount):
	for s in sharpness:
		if s.value > 0:
			var diff = amount - s.value
			s.value -= amount
			amount = diff
			if s.value < 0:
				s.value = 0
			if amount <= 0:
				break
	update_animation()

func sharpen(amount):
	for s in sharpness:
		if s.value < s.max_val:
			s.value = s.max_val
			amount -= s.max_val
			if amount <= 0:
				s.value += amount
				break
	update_animation()
	return amount

func is_sharpened():
	for s in sharpness:
		if s.value < s.max_val:
			return false
	return true

func get_weapon_damage(body, impact):
	# TODO: damage modifiers
	return strength

func _on_sword_body_enter(body):
	if body != player and body is Entity:
		body.damage(get_weapon_damage(body, null), 0.0, self, player)
		$audio.play()
		blunt(1)
