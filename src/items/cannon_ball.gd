extends "usable_item.gd"


const CannonBallScene = preload("res://data/scenes/items/cannon_ball.tscn")
const Icon = preload("res://data/images/items/cannonball.png")

const fire_speed = 200

var cannon

func _init(_quantity, _player).("Cannonball", Icon, _quantity, 1, 10, _player):
	pass

func clone():
	return get_script().new(quantity, player)

func fire(cannon):
	self.cannon = cannon
	player.inventory.use_item(self)

func effect():
	var cannon_ball: RigidBody = CannonBallScene.instance()
	if cannon != null:
		# Position the cannon ball inside the cannon, but put it in cannon's parent
		# because we don't want the cannon's transform to affect the ball
		var position = cannon.get_node("ball").global_transform.origin
		cannon.get_parent().add_child(cannon_ball)
		cannon_ball.global_transform.origin = position
		# The projectile should travel forward (-Z in Godot) from the cannon
		var a: Basis = cannon.get_global_transform().basis
		var velocity = Vector3(-a.x.z, a.y.z, a.z.z) * fire_speed
		cannon_ball.set_linear_velocity(velocity)
		cannon_ball.get_node("Timer").start()
		cannon_ball.connect("body_entered", cannon_ball, "_on_CannonBall_body_entered")
		cannon = null
	else:
		player.drop_item_on_floor(cannon_ball)
	return true
