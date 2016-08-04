extends Control

onready var mode_node = get_node("mode")
onready var multiplayer_node = get_node("multiplayer")

func _ready():
	set_process_input(true)

func _input(event):
	if event.is_action_pressed("ui_cancel") and mode_node.is_visible():
		get_tree().quit()

func _on_singleplayer_pressed():
	global.start_game("Player")
	queue_free()

func _on_multiplayer_pressed():
	mode_node.hide()
	multiplayer_node.show()
