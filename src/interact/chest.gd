extends StaticBody

onready var inventory = get_node("inventory")
onready var chest_items = inventory.get_node("items")
onready var player_items = inventory.get_node("player")

var max_items = 100
var items = []
var player = null

const ITEM_SIZE = Vector2(50, 50)
const FILE = "user://chest.conf"


func open():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_node("animation").play("open")
	set_process_input(true)
	player.set_process_input(false)
	player.set_fixed_process(false)
	player.camera_node.set_process_input(false)

func close():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_node("animation").play("close")
	set_process_input(false)
	player.set_process_input(true)
	player.set_fixed_process(true)
	player.camera_node.set_process_input(true)
	player = null

func _input(event):
	if event.is_action_pressed("player_interact"):
		close()
		inventory.hide()

func interact(player):
	if self.player != null:
		return
	self.player = player
	open()

func show_inventory(node, items, max_items):
	for child in node.get_children():
		child.queue_free()
	for i in range(max_items):
		var slot
		if i < items.size():
			slot = Slot.new(items[i])
		else:
			slot = Slot.new()
		node.add_child(slot)
		slot.button.connect("pressed", self, "_on_inventory_slot_pressed", [slot])

func _on_inventory_slot_pressed(slot):
	print("Hai premuto su %s" % slot.item.name)

func _on_animation_finished():
	if player != null:
		show_inventory(chest_items, items, max_items)
		show_inventory(player_items, player.items, player.max_items)
		inventory.show_modal()

func _on_inventory_modal_close():
	close()

class Slot extends Panel:
	var item  = null
	var icon  = null
	var button = TextureButton.new()
	var label = Label.new()

	func _init(item = null):
		self.item = item
		set_custom_minimum_size(ITEM_SIZE)
		if item != null:
			icon = item.icon.get_data().resized(ITEM_SIZE.x, ITEM_SIZE.y, Image.INTERPOLATE_CUBIC)
			var tex = ImageTexture.new()
			tex.create_from_image(icon)
			button.set_normal_texture(tex)
			label.set_text(str(item.quantity))
			item.set_label_color(label)
			set_theme(preload("res://media/chest/slot_full.tres"))
		else:
			set_theme(preload("res://media/chest/slot_empty.tres"))
		add_child(button)
		add_child(label)
