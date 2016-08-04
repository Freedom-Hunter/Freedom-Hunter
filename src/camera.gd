extends Camera

onready var yaw_node = get_node("../..")
onready var pitch_node = get_node("..")
onready var player_node = get_node("../../../body")

var yaw
var pitch
var mouse_sensitivity = Vector2(0.1, 0.1)
var max_pitch = 90
var min_pitch = -90
var move_pitch = true
var pitch_unit = 12.5

func _ready():
	yaw = 180 # yaw_node.get_rotation_deg().y
	pitch = pitch_node.get_rotation_deg().x
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	set_process_input(true)
	set_fixed_process(true)

func _input(event):
	if event.type == InputEvent.MOUSE_MOTION:
		yaw = fmod(yaw - event.relative_x * mouse_sensitivity.x , 360)
		yaw_node.set_rotation_deg(Vector3(0, yaw, 0))
		if move_pitch:
			pitch = max(min(pitch - event.relative_y * mouse_sensitivity.y, max_pitch), min_pitch)
			pitch_node.set_rotation_deg(Vector3(pitch, 0, 0))
	elif event.is_action_released("player_camera_reset"):
		var basis = player_node.get_transform().basis
		yaw = rad2deg(atan2(-basis.z.x, -basis.z.z))
		yaw_node.set_rotation_deg(Vector3(0, yaw, 0))
	elif Input.is_action_pressed("camera_rotation_up") and Input.is_action_pressed("camera_rotation_lock"):
		pitch = max(min(pitch - pitch_unit, max_pitch), min_pitch)
		pitch_node.set_rotation_deg(Vector3(pitch, 0, 0))
	elif Input.is_action_pressed("camera_rotation_down") and Input.is_action_pressed("camera_rotation_lock"):
		pitch = max(min(pitch + pitch_unit, max_pitch), min_pitch)
		pitch_node.set_rotation_deg(Vector3(pitch, 0, 0))
	elif event.is_action_released("camera_lock"):
		move_pitch = not move_pitch
