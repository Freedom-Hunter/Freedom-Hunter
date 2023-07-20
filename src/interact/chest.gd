extends StaticBody3D

@onready var inventory = preload("res://data/scenes/inventory.tscn").instantiate()
@onready var inventory_items = inventory.get_node("items")
@onready var hud = get_node("/root/hud/margin/view")
@onready var animation = get_node("model/AnimationPlayer")

var player = null


func _ready():
	inventory.set_items([], 100)
	set_process_input(false)


func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		inventory.free()


func interact(player, node):
	if self.player == null:
		self.player = player
		open()


func open():
	if animation.get_current_animation() == "open":
		return
	if animation.is_playing():
		await animation.animation_finished
	$audio.play()
	animation.play("open")
	player.pause_player()
	get_viewport().get_camera_3d().set_process_input(false)
	await animation.animation_finished
	hud.open_inventories([inventory, player.inventory])
	hud.get_node("inventory").connect("popup_hide", Callable(self, "close"))
	set_process_input(true)


func close():
	set_process_input(false)
	hud.get_node("inventory").disconnect("popup_hide", Callable(self, "close"))
	hud.close_inventories()
	$audio.play()
	animation.play("close")
	await animation.animation_finished
	player.resume_player()
	get_viewport().get_camera_3d().set_process_input(true)
	player = null


func _input(event):
	if event.is_action_pressed("player_interact"):
		close()
