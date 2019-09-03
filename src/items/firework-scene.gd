extends RigidBody


func _on_animation_finished(animation):
	queue_free()


func fire():
	linear_velocity = Vector3(0, 60, 0)
	linear_velocity.x += rand_range(-20, 20)
	linear_velocity.y += rand_range(-20, 20)
	linear_velocity.z += rand_range(-20, 20)
