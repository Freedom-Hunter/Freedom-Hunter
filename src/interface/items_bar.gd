extends Control

const Item = preload("res://src/items/usable_item.gd")
var null_item = Item.new("None", preload("res://data/images/items/null.png"), 0, 0, 0, null)

var inventory
var active_item = 0  # active_item == 0 is null_item

var touch_index = null
var drag = 0


func _on_inventory_modified(inventory):
	self.inventory = inventory
	update()


func get_item(i):
	if i % (inventory.items.size() + 1) == 0:
		return null_item
	if i > 0:
		return inventory.get_item(i - 1)
	return inventory.get_item(i)


func get_active_item():
	return get_item(active_item)


func use_active_item():
	var item = get_active_item()
	if item != null_item:
		inventory.use_item(item)
		update()


func activate_next():
	active_item = wrapi(active_item + 1, 0, inventory.items.size() + 1)
	$sound.play()
	update()


func activate_prev():
	active_item = wrapi(active_item - 1, 0, inventory.items.size() + 1)
	$sound.play()
	update()


func update():
	var i = -2
	for child in $bar.get_children():
		var item = get_item(active_item + i)
		child.get_node("icon").set_texture(item.icon)
		i += 1
	var item = get_active_item()
	if item == null_item:
		$bar/use/quantity.visible = false
	else:
		$bar/use/quantity.visible = true
		$bar/use/quantity/label.text = str(item.quantity)
		item.set_label_color($bar/use/quantity/label)
	$name/label.text = item.name


func _input(event):
	if event.is_action_pressed("player_inventory_next") and not Input.is_action_pressed("camera_rotation_lock"):
		activate_next()
	elif event.is_action_pressed("player_inventory_previous") and not Input.is_action_pressed("camera_rotation_lock"):
		activate_prev()
	elif event.is_action_pressed("player_use"):
		use_active_item()
	elif event is InputEventScreenTouch:
		if event.is_pressed() and get_rect().has_point(event.pos):
			touch_index = event.index
			drag = 0
		else:
			touch_index = null
	elif event is InputEventScreenDrag and event.index == touch_index:
		drag += event.relative_x
		if drag > 50:
			activate_prev()
			drag = 0
		elif drag < -50:
			activate_next()
			drag = 0
		accept_event()
