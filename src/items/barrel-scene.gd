extends RigidBody

const Entity = preload("res://src/entities/entity.gd")

func _on_timer_timeout():
	$"explosion/animation".play("explode")
	var r = $"explosion/radius".get_shape().get_radius()
	for body in $"explosion".get_overlapping_bodies():
		if body == self:
			continue
		if body is Entity:
			var d = body.global_transform.origin - global_transform.origin
			var dmg = int((r - d.length()) * 5 + 1)
			body.damage(dmg, 0.1)
		elif body.is_in_group("explosive"):
			var diff = body.get_translation() - get_translation()
			var speed = (r - diff.length()) * 2
			var direction = diff.normalized()
			body.set_linear_velocity(direction * speed)
			if not body.get_node("explosion/animation").is_playing():
				var body_timer = body.get_node("explosion/timer")
				body_timer.stop()
				body_timer.set_wait_time(0.5)
				body_timer.start()

func _on_animation_finished(animation):
	queue_free()
