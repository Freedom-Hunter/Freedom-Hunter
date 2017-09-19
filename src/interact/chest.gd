extends StaticBody

onready var inventory = preload("res://data/scenes/inventory.tscn").instance()
onready var inventory_items = inventory.get_node("items")
onready var hud = get_node("/root/game/hud")
onready var animation = get_node("model/AnimationPlayer")
onready var sound_node = get_node("sound")

var player = null

func _ready():
	inventory.init([], 100)

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		inventory.free()

func interact(player):
	if self.player == null:
		self.player = player
		open()

func open():
	if animation.get_current_animation() == "open":
		return
	if animation.is_playing():
		yield(animation, "finished")
	sound_node.play("hinge")
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
	sound_node.play("hinge")
	animation.play("close")
	yield(animation, "finished")
	player.resume_player()
	player = null

func _input(event):
	if event.is_action_pressed("player_interact"):
		close()
