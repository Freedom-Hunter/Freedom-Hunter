extends "usable_item.gd"
class_name CannonBall


const CannonBallScene = preload("res://data/scenes/items/cannon_ball.tscn")
const Icon = preload("res://data/images/items/cannonball.png")

const fire_speed = 200


func _init(_quantity).("Cannonball", Icon, _quantity, 1, 10):
	pass


func clone():
	return get_script().new(quantity)


func fire(cannon, spawn=null):
	if spawn == null:
		spawn = cannon.get_parent()
	var cannon_ball: RigidBody = CannonBallScene.instance()
	# Position the cannon ball inside the cannon, but put it in cannon's parent
	# because we don't want the cannon's transform to affect the ball
	var position = cannon.get_node("ball").global_transform.origin
	spawn.add_child(cannon_ball)
	cannon_ball.global_transform.origin = position
	# The projectile should travel forward (-Z in Godot) from the cannon
	var a: Basis = cannon.get_global_transform().basis
	var velocity = Vector3(-a.x.z, a.y.z, a.z.z) * fire_speed
	cannon_ball.set_linear_velocity(velocity)
	cannon_ball.get_node("Timer").start()
	cannon_ball.connect("body_entered", cannon_ball, "_on_CannonBall_body_entered")
	self.quantity -= 1


func effect(player):
	# If the player uses the cannon ball (presses Q) just drop it on the ground.
	var cannon_ball: RigidBody = CannonBallScene.instance()
	player.drop_item_on_floor(cannon_ball)
	return true
