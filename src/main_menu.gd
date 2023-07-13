extends Control

onready var global = get_node("/root/global")


func _ready():
	$mode/singleplayer.grab_focus()


func _input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		$mode.show()
		$credits.hide()
		$multiplayer.hide()
		$back.hide()
		$mode/singleplayer.grab_focus()


func _on_singleplayer_pressed():
	$Animation.play("chose")
	yield($Animation, "animation_finished")
	global.start_game("Player")
	queue_free()


func _on_multiplayer_pressed():
	$Animation.play("chose")
	yield($Animation, "animation_finished")
	$mode.hide()
	$multiplayer.show()
	$back.show()
	$back.grab_focus()


func _on_credits_pressed():
	$Animation.play("chose")
	yield($Animation, "animation_finished")
	$mode.hide()
	$credits.show()
	$back.show()
	$back.grab_focus()


func _on_back_pressed():
	$mode.show()
	$back.hide()
	$multiplayer.hide()
	$credits.hide()
	$mode/singleplayer.grab_focus()
