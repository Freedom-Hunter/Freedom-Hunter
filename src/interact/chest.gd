extends StaticBody

export var max_items = 100
var items = []

onready var inventory = get_node("inventory")
onready var grid = inventory.get_node("grid")

var player = null

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
	items = player.items
	open()

func show_inventory():
	for child in grid.get_children():
		child.queue_free()
	for i in range(max_items):
		var panel = Panel.new()
		panel.set_custom_minimum_size(Vector2(50, 50))
		if i < items.size():
			var button = TextureButton.new()
			var image = items[i].icon.get_data().resized(50, 50, Image.INTERPOLATE_CUBIC)
			var tex = ImageTexture.new()
			tex.create_from_image(image)
			button.set_normal_texture(tex)
			panel.add_child(button)
		grid.add_child(panel)
	inventory.show_modal()

func _on_animation_finished():
	if player != null:
		show_inventory()

func _on_inventory_modal_close():
	close()
