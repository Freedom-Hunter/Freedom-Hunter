extends Panel

const ITEM_SIZE = Vector2(50, 50)

var items = []
var items_node
var max_items
var active_item = 0
var hud

var columns

func init(items_array, max_items_int, hud_node=null):
	items = items_array
	items_node = get_node("items")
	max_items = max_items_int
	hud = hud_node
	columns = items_node.get_columns()
	var added = 0
	for item in items:
		if item.quantity > 0:
			var slot = Slot.new(self, item)
			slot.set_name(item.name)
			items_node.add_child(slot)
			added += 1
	for i in range(added, max_items):
		var slot = Slot.new(self)
		slot.set_name(str(i % columns, '|', int(i / columns)))
		items_node.add_child(slot)

func add_item(item):
	for e in items:
		if e.name == item.name:
			var r = e.add(item.quantity)
			items_node.get_node(item.name).set_item(e)
			return r
	if items.size() < max_items:
		items.append(item)
		for slot in items_node.get_children():
			if slot.get_name().find('|') != -1:
				slot.set_item(item)
				slot.set_name(item.name)
				return 0
	return item.quantity

func use_item(i):
	var item = items[i]
	item.use()
	if item.quantity <= 0 and not item.keep:
		remove_item(i)
	return item

func remove_item(i):
	var slot = items_node.get_node(items[i].name)
	slot.set_item(null)
	slot.set_name(str(slot.get_index() % columns, '|', int(slot.get_index() / columns)))
	items.remove(i)
	if items.size() > 0 and i == active_item:
		active_item = (active_item + 1) % items.size()

func erase_item(item):
	var i = items.find(item)
	if i != -1:
		remove_item(i)

func use_active_item():
	return use_item(active_item)

func activate_next():
	active_item = (active_item + 1) % items.size()

func activate_prev():
	active_item = (active_item - 1) % items.size()
	if active_item < 0:
		active_item = items.size() - 1


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
			if item.max_quantity > 1:
				label.set_text(str(item.quantity))
				item.set_label_color(label)
		else:
			set_texture(null)
			label.set_text("")

class Slot extends Panel:
	var Item = preload("res://src/items/item.gd")
	var item
	var stack
	var inventory

	func _init(inv, _item = null):
		stack = ItemStack.new()
		stack.set_name("stack")
		add_child(stack)
		set_item(_item)
		set_custom_minimum_size(ITEM_SIZE)
		inventory = inv

	func set_item(i):
		item = i
		if item != null:
			set_theme(preload("res://media/inventory/slot_full.tres"))
		else:
			set_theme(preload("res://media/inventory/slot_empty.tres"))
		stack.layout(item)

	func get_drag_data(pos):
		if item != null:
			var preview = ItemStack.new()
			preview.layout(item)
			set_drag_preview(preview)
			var ret_item = item
			inventory.erase_item(item)
			return {'item': ret_item, 'inventory': inventory}

	func can_drop_data(pos, data):
		return true

	func drop_data(pos, data):
		if item == null or data.item.name == item.name:
			inventory.add_item(data.item) # take this item
		else:
			data.inventory.add_item(data.item) # give this item back
