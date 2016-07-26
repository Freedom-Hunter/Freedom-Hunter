extends Camera

onready var yaw_node = get_node("../..")
onready var pitch_node = get_node("..")
onready var player_node = get_node("/root/game/player/body")
var yaw = 0
var pitch = 0
export var mouse_sensitivity = Vector2(0.1, 0.1)
export var max_pitch = 30
export var min_pitch = 10

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	set_process_input(true)
	set_fixed_process(true)

func _input(event):
	if event.type == InputEvent.MOUSE_MOTION:
		yaw = fmod(yaw - event.relative_x * mouse_sensitivity.x , 360)
		pitch = max(min(pitch - event.relative_y * mouse_sensitivity.y, max_pitch), -min_pitch)
		yaw_node.set_rotation_deg(Vector3(0, yaw, 0))
		pitch_node.set_rotation_deg(Vector3(pitch, 0, 0))
	elif event.is_action_released("player_camera_reset"):
		var basis = player_node.get_transform().basis
		yaw = rad2deg(atan2(basis.z.x, basis.z.z))
		yaw_node.set_rotation_deg(Vector3(0, yaw, 0))
