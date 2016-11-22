extends StaticBody

onready var inventory = preload("res://scene/inventory.tscn").instance()
onready var inventory_items = inventory.get_node("items")
onready var hud = get_node("/root/game/hud")
onready var animation = get_node("animation")

var player = null

func _ready():
	inventory.init([], 100)

func interact(player):
	if self.player == null:
		self.player = player
		open()

func open():
	if animation.get_current_animation() == "open":
		return
	if animation.is_playing():
		yield(animation, "finished")
	animation.play("open")
	player.pause_player()
	yield(animation, "finished")
	hud.open_inventories([inventory, player.inventory])
	hud.inventory.connect("popup_hide", self, "close")
	set_process_input(true)

func close():
	set_process_input(false)
	hud.inventory.disconnect("popup_hide", self, "close")
	hud.close_inventories()
	animation.play("close")
	yield(animation, "finished")
	player.resume_player()
	player = null

func _input(event):
	if event.is_action_pressed("player_interact"):
		close()
