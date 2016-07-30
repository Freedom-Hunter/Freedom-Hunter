extends RigidBody

onready var light_node = get_node("explosion/light")
onready var particle_node = get_node("explosion/particles")
onready var animation_node = get_node("explosion/animation")
onready var Entity = preload("res://src/entities/entity.gd")

func _on_timer_timeout():
	animation_node.play("explode")
	var r = get_node("explosion/radius").get_shape().get_radius()
	for body in get_node("explosion").get_overlapping_bodies():
		if body == self:
			continue
		if body extends Entity:
			var d = body.get_translation() - get_translation()
			var dmg = int((r - d.length()) * 5 + 1)
			body.damage(dmg, 0.1)
		elif body.is_in_group("explosive"):
			var diff = body.get_translation() - get_translation()
			var speed = (r - diff.length()) * 2
			var direction = diff.normalized()
			body.set_linear_velocity(direction * speed)
			if not body.animation_node.is_playing():
				var timer = body.get_node("explosion/timer")
				timer.stop()
				timer.set_wait_time(0.5)
				timer.start()

func _on_animation_finished():
	queue_free()
