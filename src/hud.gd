extends Control

onready var life_node = get_node("hp")
onready var damage_node = get_node("hp/red_hp")
onready var stamina_node = get_node("stamina")
onready var names_node = get_node("names")
onready var players_list_node = get_node("players_list")

var local_player

func init(local_player):
	self.local_player = local_player.get_node("body")

func _ready():
	set_process(true)
	if networking.multiplayer:
		set_process_input(true)

func _input(event):
	if Input.is_action_pressed("players_list"):
		players_list_node.show()
	else:
		players_list_node.hide()

func _process(delta):
	update_values()
	update_items()
	update_names()

func update_values():
	life_node.set_value(local_player.hp)
	damage_node.set_value(local_player.regenerable_hp)
	stamina_node.set_value(local_player.stamina)

func update_items():
	var i = -2
	for child in get_node("items_bar").get_children():
		if child extends Panel:
			var item = local_player.items[(local_player.active_item + i) % local_player.items.size()]
			child.get_node("icon").set_texture(item.icon)
			i += 1
	var item = local_player.items[local_player.active_item]
	get_node("items_bar/quantity/label").set_text(str(item.quantity))
	get_node("items_bar/name/label").set_text(item.name)

func update_names():
	var local_player_pos = local_player.get_global_transform().origin
	for player in get_node("../player_spawn").get_children():
		var name = player.get_name()
		if not names_node.has_node(name):
			var label = Label.new()
			label.set_name(name)
			label.set_text(name)
			label.set_align(Label.ALIGN_CENTER)
			label.set_valign(Label.VALIGN_CENTER)
			names_node.add_child(label)
		var player_pos = player.get_node("body/name").get_global_transform().origin
		var camera = get_viewport().get_camera()
		var label = get_node("names/" + player.get_name())
		if camera.is_position_behind(player_pos):
			label.hide()
		else:
			label.show()
		var pos = camera.unproject_position(player_pos)
		var size = label.get_size()
		label.set_pos(pos - Vector2(size.x/2, size.y/2))
		if not get_node("players_list").has_node(player.get_name()):
			var label = Label.new()
			label.set_name(name)
			label.set_text(name)
			players_list_node.add_child(label)

func got_item(item):
	var label = get_node("itemget/label")
	label.set_text("You got %s" % item.name)
	get_node("itemget/animation").play("show")
