class_name CannonBallNode
extends RigidBody3D


var velocity_last_frame := Vector3()


func _physics_process(_delta):
	velocity_last_frame = linear_velocity


func _on_CannonBall_body_entered(body:Node):
	var momentum : float = velocity_last_frame.length() * mass
	if momentum > 200:
		($AnimationPlayer as AnimationPlayer).play("explode")
		if body is Entity:
			(body as Entity).damage(momentum, 0.1)


func _on_Timer_timeout():
	queue_free()


func _on_AnimationPlayer_animation_finished(anim_name: String):
	if anim_name != "SETUP":
		queue_free()


func interact(player, node):
	var item: Consumable = load("res://src/items/consumables/cannon_ball.gd").new(1)
	var remainder = player.add_item(item)
	if remainder == 0:
		queue_free()


func fire(velocity: Vector3) -> void:
	set_linear_velocity(velocity)
	body_entered.connect(_on_CannonBall_body_entered)
