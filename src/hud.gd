extends Object

onready var life_node = get_node("hp")
onready var damage_node = get_node("hp/red_hp")
onready var stamina_node = get_node("stamina")

func update_values(hp, reg, stamina):
	life_node.set_value(hp)
	damage_node.set_value(reg)
	stamina_node.set_value(stamina)

func scroll(items, active_item):
	var i = -2
	for child in get_node("items_bar").get_children():
		if child extends Panel:
			var item = items[(active_item + i) % items.size()]
			child.get_node("icon").set_texture(item.icon)
			i += 1
	update_quantity(items, active_item)

func update_quantity(items, active_item):
	var item = items[active_item]
	get_node("items_bar/quantity/label").set_text(str(item.quantity))
	get_node("items_bar/name/label").set_text(item.name)
