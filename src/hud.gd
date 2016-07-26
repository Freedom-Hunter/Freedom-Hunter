extends Object

onready var life_node = get_node("hp")
onready var damage_node = get_node("hp/red_hp")
onready var stamina_node = get_node("stamina")

func update_values(hp, reg, stamina):
	life_node.set_value(hp)
	damage_node.set_value(reg)
	stamina_node.set_value(stamina)
