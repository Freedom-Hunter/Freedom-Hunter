# SPDX-FileCopyrightText: 2023 Elia Argentieri
#
# SPDX-License-Identifier: GPL-3.0-or-later

@tool
extends MultiMeshInstance3D


@export var span: float = 5.0: set = set_span
@export var count: int = 1000: set = set_count
@export var width: Vector2 = Vector2(0.01, 0.02): set = set_width
@export var height: Vector2 = Vector2(0.04, 0.08): set = set_height
@export var sway_yaw: Vector2 = Vector2(0.0, 10.0): set = set_sway_yaw
@export var sway_pitch: Vector2 = Vector2(0.0, 10.0): set = set_sway_pitch


func _init():
	rebuild()


func _ready():
	rebuild()


func rebuild():
	if !multimesh:
		multimesh = MultiMesh.new()
	multimesh.instance_count = 0
	multimesh.mesh = GrassFactory.simple_grass()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.set_custom_data_format(MultiMesh.CUSTOM_DATA_FLOAT)
	multimesh.set_color_format(MultiMesh.COLOR_NONE)
	multimesh.instance_count = count
	
	for index in (multimesh.instance_count):
		var pos = Vector3(randf_range(-span, span), 0.0, randf_range(-span, span))
		var basis = Basis(Vector3.UP, deg_to_rad(randf_range(0, 359)))
		multimesh.set_instance_transform(index, Transform3D(basis, pos))
		multimesh.set_instance_custom_data(index, Color(
			randf_range(width.x, width.y),
			randf_range(height.x, height.y),
			deg_to_rad(randf_range(sway_pitch.x, sway_pitch.y)),
			deg_to_rad(randf_range(sway_yaw.x, sway_yaw.y))
		))


func set_span(p_span):
	span = p_span
	rebuild()


func set_count(p_count):
	count = p_count
	rebuild()


func set_width(p_width):
	width = p_width
	rebuild()


func set_height(p_height):
	height = p_height
	rebuild()


func set_sway_yaw(p_sway_yaw):
	sway_yaw = p_sway_yaw
	rebuild()


func set_sway_pitch(p_sway_pitch):
	sway_pitch = p_sway_pitch
	rebuild()

