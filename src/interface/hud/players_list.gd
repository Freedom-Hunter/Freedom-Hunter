# SPDX-FileCopyrightText: 2023 Elia Argentieri
#
# SPDX-License-Identifier: GPL-3.0-or-later

extends VBoxContainer


@onready var global: GlobalAutoload = get_node("/root/global")


func _ready():
	if multiplayer.has_multiplayer_peer():
		global.player_connected.connect(_on_player_connected)
		global.player_disconnected.connect(_on_player_disconnected)
	else:
		set_process_input(false)
	hide()


func new_label(text: String) -> Label:
	var label := Label.new()
	label.set_name(text)
	label.set_text(text)
	return label


func _on_player_connected(player_name: String) -> void:
	add_child(new_label(player_name))


func _on_player_disconnected(player_name: String) -> void:
	get_node(player_name).queue_free()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("players_list"):
		show()
	elif event.is_action_released("players_list"):
		hide()
