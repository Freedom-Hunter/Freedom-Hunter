extends StaticBody

onready var inventory = get_node("inventory")
onready var inventory_items = inventory.get_node("items")
onready var hud = get_node("/root/game/hud")
onready var animation = get_node("animation")

var max_items = 100
var items = []
var player = null

func interact(player):
	if self.player != null:
		return
	self.player = player
	open()

func open():
	animation.play("open")
	set_process_input(true)
	player.pause_player()
	yield(animation, "finished")
	hud.show_player_inventory()
	inventory.show_inventory(items, max_items)
	inventory.connect("modal_close", self, "close")
	hud.inventory.connect("modal_close", self, "close")

func close():
	inventory.hide_inventory()
	hud.hide_player_inventory()
	inventory.disconnect("modal_close", self, "close")
	hud.inventory.disconnect("modal_close", self, "close")
	animation.play("close")
	set_process_input(false)
	if player.local:
		player.resume_player()
	player = null

func _input(event):
	if event.is_action_pressed("player_interact"):
		close()
