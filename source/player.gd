extends KinematicBody

const GRAVITY = -9.81
export var SPEED = 5
export var JUMP = 5
export var SPRINT_SPEED = 1.5
const SPRINT_USE = 5
const SPRINT_REGENERATION = 4
const MAX_SLOPE_ANGLE = 30
const COLLISION_SPEED_HURT = 10

onready var camera_node = get_node("../yaw/pitch/camera")
onready var yaw_node = get_node("../yaw")
onready var weapon_node = get_node("weapon/sword")

onready var stamina_node = get_node("/root/game/hud/stamina")
onready var life_node = get_node("/root/game/hud/life")
onready var hp = life_node.get_value()
onready var damage_node = get_node("/root/game/hud/life/damage")
onready var debug = get_node("/root/game/hud/debug")

# Player movements
var velocity = Vector3()
var on_floor = false
var floor_vel = Vector3()

# Player attack
var rot = 0
var down = true

func fh_rotation(direction, delta):
	if direction.length() != 0:
		var target = Vector3(direction.x, 0, direction.z).normalized()
		target = -(get_transform().basis.z).linear_interpolate(target, delta * 10)
		target += get_global_transform().origin
		look_at(target, Vector3(0, 1, 0))

func _ready():
	set_fixed_process(true)
	set_process_input(true)
	print("Start play")

func _input(event):
	if event.is_action_released("debug_camera"):
		if camera_node.is_current():
			get_node("/root/game/cam").make_current()
		else:
			camera_node.make_current()
	elif event.is_action_released("debug_reset_pos"):
		get_tree().change_scene("res://scene/game.scn")
	elif event.is_action_pressed("ui_cancel"):
		get_tree().quit()


func _fixed_process(delta):
	var direction = Vector3(0, 0, 0)
	var camera = camera_node.get_global_transform()
	
	# Player movements
	var speed = SPEED
	var stamina = stamina_node.get_value()
	if Input.is_action_pressed("player_forward"):
		direction -= Vector3(camera.basis.z.x, 0, camera.basis.z.z)
	if Input.is_action_pressed("player_backward"):
		direction += Vector3(camera.basis.z.x, 0, camera.basis.z.z)
	if Input.is_action_pressed("player_left"):
		direction -= Vector3(camera.basis.x.x, 0, camera.basis.x.z)
	if Input.is_action_pressed("player_right"):
		direction += Vector3(camera.basis.x.x, 0, camera.basis.x.z)
	if Input.is_action_pressed("player_run"):
		if stamina > 0:
			speed *= SPRINT_SPEED
			stamina_node.set_value(stamina - (SPRINT_USE * delta))
	else:
		stamina_node.set_value(stamina + (SPRINT_REGENERATION * delta))
	if Input.is_action_pressed("player_jump") and on_floor:
		if Input.is_action_pressed("player_run"):
			velocity.y += JUMP * SPRINT_SPEED
		else:
			velocity.y += JUMP
	direction = direction.normalized()
		
	# Model rotation
	fh_rotation(direction, delta)
	
	
	# Player collision
	velocity.x = direction.x * speed
	velocity.y += GRAVITY * delta
	velocity.z = direction.z * speed

	var motion = move(velocity * delta)
	on_floor = false
	floor_vel = Vector3()
	if is_colliding():
		var n = get_collision_normal()
		if (rad2deg(acos(n.dot(Vector3(0, 1, 0)))) < MAX_SLOPE_ANGLE):
			on_floor = true
			floor_vel = get_collider_velocity()
			move(floor_vel * delta)
			if velocity.length() >= COLLISION_SPEED_HURT:
				hp -= 1
				life_node.set_value(hp)
				if hp == 0:
					get_node("audio").play("hit")
					rotate_x(PI/2)
					set_fixed_process(false)
		motion = n.slide(motion)
		velocity = n.slide(velocity)
		move(motion)
	
	if Input.is_action_pressed("player_attack"):
		if down:
			rot = fmod(rot + delta*100, 90)
		else:
			rot = fmod(rot - delta*100, 90)
		if rot > 85 and down:
			down = false
		elif rot < 5 and not down:
			down = true
		weapon_node.set_rotation_deg(Vector3(rot, 0, 0))
	
	yaw_node.set_translation(get_translation() + Vector3(0, 1.5, 0))
	debug.set_text("Pos %s" % [get_translation()])

func _on_sword_body_enter( body ):
	if body.get_name() == "Dragon":
		body.hit()
