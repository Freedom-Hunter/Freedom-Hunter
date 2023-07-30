extends StaticBody3D

@onready var inventory = preload("res://data/scenes/inventory.tscn").instantiate()
@onready var inventory_items = inventory.get_node("items")
@onready var hud_inventory = $/root/hud/inventory
@onready var animation = $AnimationPlayer

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
	hud_inventory.open_inventories([inventory, player.inventory])
	hud_inventory.popup_hide.connect(close)
	set_process_input(true)


func close():
	set_process_input(false)
	hud_inventory.popup_hide.disconnect(close)
	hud_inventory.close_inventories()
	$audio.play()
	animation.play("close")
	await animation.animation_finished
	player.resume_player()
	get_viewport().get_camera_3d().set_process_input(true)
	player = null


func _input(event: InputEvent):
	if event.is_action_pressed("player_interact"):
		close()

