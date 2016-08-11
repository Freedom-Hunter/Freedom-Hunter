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
		if i < items.size():
			Slot.new(node, items[i])
		else:
			Slot.new(node)

func _on_animation_finished():
	if player != null:
		show_inventory(chest_items, items, max_items)
		show_inventory(player_items, player.items, player.max_items)
		inventory.show_modal()

func _on_inventory_modal_close():
	close()

class Slot extends Control:
	var item  = null
	var icon  = null
	var panel = Panel.new()
	var label = Label.new()

	func _init(parent, item = null):
		self.item = item
		self.panel.set_custom_minimum_size(ITEM_SIZE)
		var button = TextureButton.new()
		if self.item != null:
			self.icon = item.icon.get_data().resized(ITEM_SIZE.x, ITEM_SIZE.y, Image.INTERPOLATE_CUBIC)
			var tex = ImageTexture.new()
			tex.create_from_image(self.icon)
			button.set_normal_texture(tex)
			self.label.set_text(str(item.quantity))
			item.set_label_color(self.label)
			self.panel.set_theme(preload("res://media/chest/slot_full.tres"))
		else:
			self.panel.set_theme(preload("res://media/chest/slot_empty.tres"))
		self.panel.add_child(button)
		self.panel.add_child(self.label)
		parent.add_child(self.panel)
