extends PopupPanel

const ITEM_SIZE = Vector2(50, 50)

func _notification(what):
	if what == NOTIFICATION_POPUP_HIDE:
		print("Popup hide ", get_path())

func show_inventory(items, max_items):
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	var columns = get_node("items").get_columns()
	for i in range(max_items):
		var slot
		if i < items.size() and items[i].quantity > 0:
			slot = Slot.new(items[i])
		else:
			slot = Slot.new()
		slot.set_name(str(i % columns, '|', int(i / columns)))
		get_node('items').add_child(slot)
	popup()

func hide_inventory():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	for child in get_node('items').get_children():
		child.free()
	hide()

class ItemStack extends TextureFrame:
	var label = Label.new()

	func _init():
		label.set_name("quantity")
		add_child(label)
		set_expand(true)
		set_stretch_mode(STRETCH_KEEP_ASPECT)
		set_size(ITEM_SIZE)

	func layout(item):
		if item != null:
			set_texture(item.icon)
			label.set_text(str(item.quantity))
			item.set_label_color(label)
		else:
			set_texture(null)
			label.set_text("")

class Slot extends Panel:
	var Item = preload("res://src/items/item.gd")
	var item
	var stack

	func _init(item = null):
		self.item = item
		stack = ItemStack.new()
		stack.set_name("stack")
		add_child(stack)
		layout()
		set_custom_minimum_size(ITEM_SIZE)

	func layout():
		if item != null:
			set_theme(preload("res://media/inventory/slot_full.tres"))
		else:
			set_theme(preload("res://media/inventory/slot_empty.tres"))
		stack.layout(item)

	func get_drag_data(pos):
		print_stack()
		if item != null:
			var preview = ItemStack.new()
			preview.layout(item)
			set_drag_preview(preview)
			var ret_item = Item.new()
			ret_item.clone(item)
			item = null
			layout()
			return {'slot': self, 'item': ret_item}

	func can_drop_data(pos, data):
		print_stack()
		return true

	func drop_data(pos, data):
		print_stack()
		if item == null:
			item = data.item
		elif data.item.name == item.name:
			item.quantity += data.item.quantity
		else:
			data.slot.item = data.item
			data.slot.layout()
		layout()
