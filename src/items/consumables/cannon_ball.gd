class_name CannonBall
extends Consumable


const CannonBallScene = preload("res://data/scenes/items/cannon_ball.tscn")
const Icon = preload("res://data/images/items/cannonball.png")

const fire_speed = 200


func _init(_quantity):
	super("Cannonball", Icon, _quantity, 1, 10)
	pass


func clone() -> CannonBall:
	return get_script().new(quantity)


func fire(from_cannon: CannonNode, spawn:Node3D=null) -> void:
	if spawn == null:
		spawn = from_cannon.get_parent()
	var cannon_ball: CannonBallNode = CannonBallScene.instantiate()
	# Position the cannon ball inside the cannon, but put it in cannon's parent
	# because we don't want the cannon's transform to affect the ball
	var position := from_cannon.ball_spawn.global_position
	spawn.add_child(cannon_ball)
	cannon_ball.global_transform.origin = position
	# The projectile should travel forward (-Z in Godot) from the cannon
	var a: Basis = from_cannon.global_transform.basis
	var velocity := Vector3(-a.x.z, a.y.z, a.z.z) * fire_speed
	cannon_ball.fire(velocity)
	self.quantity -= 1


func effect(player: Player) -> bool:
	# If the player uses the cannon ball (presses Q) just drop it on the ground.
	var cannon_ball: CannonBallNode = CannonBallScene.instantiate()
	player.drop_item_on_floor(cannon_ball)
	return true
