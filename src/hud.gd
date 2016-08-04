extends Control

onready var life_node = get_node("hp")
onready var damage_node = get_node("hp/red_hp")
onready var stamina_node = get_node("stamina")
onready var names_node = get_node("names")

var players = []

func init():
	players = get_node("../player_spawn").get_children()
	for player in players:
		var label = Label.new()
		var name = player.get_name()
		label.set_name(name)
		label.set_text(name)
		label.set_align(Label.ALIGN_CENTER)
		label.set_valign(Label.VALIGN_CENTER)
		names_node.add_child(label)
	set_process(true)

func _process(delta):
	for player in players:
		var pos = get_viewport().get_camera().unproject_position(player.get_node("body/name").get_global_transform().origin)
		var label = get_node("names/" + player.get_name())
		var size = label.get_size()
		label.set_pos(pos - Vector2(size.x/2, size.y/2))

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

func got_item(item):
	var label = get_node("itemget/label")
	label.set_text("You got %s" % item.name)
	get_node("itemget/animation").play("show")
