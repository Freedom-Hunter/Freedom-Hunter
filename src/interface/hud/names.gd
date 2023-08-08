# SPDX-FileCopyrightText: 2023 Elia Argentieri
#
# SPDX-License-Identifier: GPL-3.0-or-later

extends Control


@onready var global: GlobalAutoload = get_node("/root/global")


func _ready():
	if multiplayer.has_multiplayer_peer():
		global.player_connected.connect(_on_player_connected)
		global.player_disconnected.connect(_on_player_disconnected)
	else:
		set_process(false)
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


func _process(delta: float):
	var camera_node := get_viewport().get_camera_3d()
	var camera_pos := camera_node.global_position
	var space_state: PhysicsDirectSpaceState3D = global.game.get_world_3d().get_direct_space_state()
	if multiplayer.has_multiplayer_peer():
		for player in networking.get_players():
			var _name: String = player.get_name()
			var player_pos: Vector3 = player.get_name_position()
			var label: Label = get_node(NodePath(_name))
			if camera_node.is_position_behind(player_pos):
				label.hide()
			else:
				# use global coordinates, not local to node
				var query := PhysicsRayQueryParameters3D.new()
				query.from = camera_pos
				query.to = player_pos
				query.exclude = networking.get_players()
				var result := space_state.intersect_ray(query)
				if not result.is_empty():
					label.hide()
				else:
					label.show()
					var pos := camera_node.unproject_position(player_pos)
					var label_size := label.get_size()
					label.global_position = pos - label_size / 2
	else:
		var label: Label = get_node(NodePath(global.local_player.get_name()))
		var pos := camera_node.unproject_position(global.local_player.get_name_position())
		var label_size: Vector2 = label.get_size()
		label.global_position = pos - label_size / 2
