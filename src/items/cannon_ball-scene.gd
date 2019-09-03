extends RigidBody

const Entity = preload("res://src/entities/entity.gd")

var velocity_last_frame = Vector3()


func _physics_process(delta):
	velocity_last_frame = linear_velocity


func _on_CannonBall_body_entered(body:Node):
	var momentum = velocity_last_frame.length() * mass
	if momentum > 200:
		$AnimationPlayer.play("explode")
		if body is Entity:
			body.damage(momentum, 0.1)


func _on_Timer_timeout():
	queue_free()


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name != "SETUP":
		queue_free()


func interact(player, node):
	var remainder = player.add_item(load("res://src/items/cannon_ball.gd").new(1, null))
	if remainder == 0:
		queue_free()
