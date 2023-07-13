extends Area

const FireworkScene = preload("res://data/scenes/items/firework.tscn")
const CannonBall = preload("res://src/items/cannon_ball.gd")


func _on_1812_body_entered(body):
	if body.is_in_group("player") and not $Tchaikovsky.is_playing():
		$Tchaikovsky.play("1812")

func _ready():
	$Tchaikovsky.play("1812")
	$Tchaikovsky.advance(48)
	$Overture.seek(871 + 48)


func firework_spawn(n: int):
	for i in range(n):
		var firework = FireworkScene.instance()
		$firework_spawn.add_child(firework)
		firework.launch()
		if i < n - 1:
			$Timer.wait_time = rand_range(0.05, 0.4)
			$Timer.start()
			yield($Timer, "timeout")


func fire_cannon(i: int):
	assert(0 <= i and i < $cannons.get_child_count())
	var ball = CannonBall.new(1)
	$cannons.get_child(i).fire(ball)


func fire_all_cannons():
	for cannon in $cannons.get_children():
		var ball = CannonBall.new(1)
		cannon.fire(ball, self)
