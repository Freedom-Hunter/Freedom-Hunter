extends RigidBody


func launch():
	linear_velocity = Vector3(0, 70, 0)
	linear_velocity.x += rand_range(-20, 20)
	linear_velocity.y += rand_range(-20, 20)
	linear_velocity.z += rand_range(-20, 20)
	$animation.play("launch")
	$Timer.wait_time += rand_range(0, 1)
	$Timer.start()
	yield($Timer, "timeout")
	$animation.play("boom")
	yield($animation, "animation_finished")
	queue_free()
