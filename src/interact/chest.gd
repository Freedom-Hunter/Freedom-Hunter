extends StaticBody

onready var inventory = preload("res://scene/inventory.tscn").instance()
onready var inventory_items = inventory.get_node("items")
onready var hud = get_node("/root/game/hud")
onready var animation = get_node("animation")

var player = null

func _ready():
	inventory.init([], 100)

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
	if player != null:
		hud.open_inventories([inventory, player.inventory])
		hud.inventory.connect("modal_close", self, "close")

func close():
	if hud.inventory.is_connected("modal_close", self, "close"):
		hud.inventory.disconnect("modal_close", self, "close")
	hud.close_inventories()
	animation.play("close")
	set_process_input(false)
	player.resume_player()
	player = null

func _input(event):
	if event.is_action_pressed("player_interact"):
		close()
