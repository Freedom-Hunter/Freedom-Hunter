extends Control

var touch_index = null
var drag = 0

signal activate_next
signal activate_prev


func _ready():
	if OS.has_touchscreen_ui_hint():
		set_process_input(true)

func _on_inventory_modified(inventory):
	var i = -2
	for child in $bar.get_children():
		if child is Panel:
			var item = inventory.get_item(inventory.active_item + i)
			child.get_node("icon").set_texture(item.icon)
			i += 1
	var item = inventory.items[inventory.active_item]
	$bar/use/quantity/label.text = str(item.quantity)
	item.set_label_color($bar/use/quantity/label)
	$name/label.text = item.name
	$sound.play()

func _input(event):
	if event is InputEventScreenTouch:
		if event.is_pressed() and get_rect().has_point(event.pos):
			touch_index = event.index
			drag = 0
		else:
			touch_index = null
	elif event is InputEventScreenDrag and event.index == touch_index:
		drag += event.relative_x
		if drag > 50:
			emit_signal("activate_prev")
			drag = 0
		elif drag < -50:
			emit_signal("activate_next")
			drag = 0
		accept_event()
