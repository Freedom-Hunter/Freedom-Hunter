extends Area3D

const FireworkScene = preload("res://data/scenes/items/firework.tscn")


func _on_1812_body_entered(body):
	if body.is_in_group("player") and not $Tchaikovsky.is_playing():
		$Tchaikovsky.play("1812")


func _ready():
	#$Tchaikovsky.play("1812")
	#$Tchaikovsky.advance(48)
	#$Overture.seek(871 + 48)
	pass


func firework_spawn(n: int):
	for i in range(n):
		var firework: FireworkNode = FireworkScene.instantiate()
		$firework_spawn.add_child(firework)
		firework.launch()
		if i < n - 1:
			await get_tree().create_timer(randf_range(0.05, 0.2)).timeout


func fire_cannon(i: int):
	if 0 <= i and i < $cannons.get_child_count():
		var ball := CannonBall.new(1)
		$cannons.get_child(i).fire(ball)


func fire_all_cannons():
	for cannon in $cannons.get_children():
		var ball := CannonBall.new(1)
		cannon.fire(ball, self)
