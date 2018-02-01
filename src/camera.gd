extends Camera

onready var yaw_node = get_node("../..")
onready var pitch_node = get_node("..")
onready var onscreen_node = get_node("/root/game/hud/onscreen")

var target_yaw
var target_pitch
var yaw
var pitch
var mouse_sensitivity = Vector2(0.1, 0.1)
var gyro_sensitivity = Vector2(1, -1)
var gyro_enabled = true
var touch_sensitivity = Vector2(0.25, 0.25)
var touch_index = null
var max_pitch = 90
var min_pitch = -90
var move_pitch = true
var pitch_unit = 12.5
var camera_distance = 8

func _ready():
	target_yaw = yaw_node.get_rotation_degrees().y
	yaw = target_yaw
	target_pitch = pitch_node.get_rotation_degrees().x
	pitch = target_pitch
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	set_process_input(true)
	set_process(true)

func _process(delta):
	yaw = lerp(yaw, target_yaw, delta * 10)
	pitch = lerp(pitch, target_pitch, delta * 5)
	yaw_node.set_rotation_degrees(Vector3(0, yaw, 0))
	pitch_node.set_rotation_degrees(Vector3(pitch, 0, 0))
	camera_zoom(delta * 10)
	if gyro_enabled:
		var gyro = Input.get_gyroscope()
		if gyro != Vector3():
			rotate_view(Vector2(gyro.y, gyro.x) * gyro_sensitivity)

func rotate_view(relative):
	target_yaw -= relative.x
	if target_yaw >= 360:
		target_yaw -= 360
		yaw -= 360
	if target_yaw <= -360:
		target_yaw += 360
		yaw += 360
	if move_pitch:
		target_pitch = max(min(target_pitch - relative.y, max_pitch), min_pitch)

func _input(event):
	if event is InputEventScreenTouch:
		if event.is_pressed() and event.index != onscreen_node.touch_index:
			touch_index = event.index
		else:
			touch_index = null
	elif event is InputEventScreenDrag and event.index == touch_index and event.index != onscreen_node.touch_index:
		rotate_view(event.relative * touch_sensitivity)
	elif event is InputEventMouseMotion and not onscreen_node.is_visible():
		rotate_view(event.relative * mouse_sensitivity)
	elif event.is_action_released("player_camera_reset"):
		var basis = global.local_player.get_transform().basis
		target_yaw = rad2deg(atan2(-basis.z.x, -basis.z.z))
	elif Input.is_action_pressed("camera_rotation_up") and Input.is_action_pressed("camera_rotation_lock") and not move_pitch:
		target_pitch = max(min(target_pitch - pitch_unit, max_pitch), min_pitch)
	elif Input.is_action_pressed("camera_rotation_down") and Input.is_action_pressed("camera_rotation_lock") and not move_pitch:
		target_pitch = max(min(target_pitch + pitch_unit, max_pitch), min_pitch)
	elif event.is_action_released("camera_lock"):
		move_pitch = not move_pitch
	elif event.is_action_released("camera_zoom_in"):
		if not camera_distance <= 1:
			camera_distance -= 0.5
	elif event.is_action_released("camera_zoom_out"):
		if not camera_distance >= 10:
			camera_distance += 0.5

func camera_zoom(delta):
	var camera_t = get_global_transform()
	var diff = (camera_t.origin - pitch_node.get_global_transform().origin).normalized() * camera_distance
	var target = pitch_node.get_global_transform().origin + diff
	target = (camera_t.origin).linear_interpolate(target, delta)
	camera_t.origin = target
	set_global_transform(camera_t)
