extends Spatial

const Player = preload("res://src/entities/player.gd")
const Item = preload("res://src/items/usable_item.gd")


func interact(player:Player, node):
	match node.name:
		"fire":
			fire(player)
		"clockwise":
			tween_rotate(-15)
		"anticlockwise":
			tween_rotate(15)
		_:
			print_debug("Not a known node")

func fire(player:Player):
	var cannon_ball: Item = player.inventory.find_item_by_name("Cannonball")
	if cannon_ball != null and not $animation.is_playing() and not $rotate.is_active():
		cannon_ball.fire(self)
		$animation.play("fire")

func tween_rotate(angle, duration=0.5):
	if not $animation.is_playing() and not $rotate.is_active():
		var initial = rotation_degrees
		var final = initial + Vector3(0, angle, 0)
		$rotate.interpolate_property(self, "rotation_degrees", 
			initial, final, duration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		$rotate.start()

