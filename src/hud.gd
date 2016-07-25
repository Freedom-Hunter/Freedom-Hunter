extends Object

export var life_regeneration = 5
var time = 0


onready var life_node = get_node("hp")
onready var damage_node = get_node("hp/red_hp")


func _ready():
	set_process(true)
	
func _process(delta):
	time += delta
	if time > life_regeneration:
		time = 0
		var damage = damage_node.get_value()
		var life = life_node.get_value()
		if damage - life > 0:
			life_node.set_value(life + 1)