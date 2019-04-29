extends Panel

const Item = preload("res://src/items/usable_item.gd")

const ITEM_SIZE = Vector2(50, 50)

var items = []
var max_slots
var dragging

# emitted when an item is added, removed or modified
signal modified


func set_items(items_array, max_slots_int):
	items = items_array
	max_slots = max_slots_int
	var added = 0
	for item in items:
		if item.quantity > 0:
			var slot = Slot.new(self, item)
			$items.add_child(slot)
			added += 1
	for _i in range(added, max_slots):
		var slot = Slot.new(self)
		$items.add_child(slot)
	emit_signal("modified", self)

# Input handling is needed to detect when the user drags and drops an item where he can't
func _input(event):
	if event is InputEventMouseButton and not event.is_pressed() and event.button_index == BUTTON_LEFT:
		call_deferred("give_back_dragged_item")

func give_back_dragged_item():
	if dragging != null:
		if dragging.in_flight:
			dragging.in_flight = false
			add_item(dragging.item, dragging.slot)
		dragging = null

func find_free_slot() -> Slot:
	for slot in $items.get_children():
		if slot.item == null:
			return slot
	return null

func find_item_by_name(_name: String) -> Item:
	for item in items:
		if item.name == _name:
			return item
	return null

# If slot is null will look for the first free slot
func add_item(item, slot=null):
	var overflow = item.quantity
	if slot == null:
		var found = find_item_by_name(item.name)
		if found != null:
			overflow = found.add(item.quantity)
			$items.get_node(item.name).stack.layout(found)
		else:
			var clone = item.clone()
			items.append(clone)
			find_free_slot().set_item(clone)
			overflow = 0
	elif slot.item != null:
		assert(slot.item.name == item.name)
		overflow = slot.item.add(item.quantity)
		slot.stack.layout(slot.item)
	else:
		var clone = item.clone()
		items.append(clone)
		slot.set_item(clone)
		overflow = 0
	emit_signal("modified", self)
	return overflow

func get_item(i: int):
	return items[wrapi(i, 0, items.size())]

func use_item(item: Item):
	item.use()
	if item.quantity <= 0:
		erase_item(item)
	emit_signal("modified", self)
	return item

func remove_item(i, slot=null):
	if slot == null:
		slot = $items.get_node(items[i].name)
	slot.set_item(null)
	items.remove(i)
	emit_signal("modified", self)

func erase_item(item, slot=null):
	var i = items.find(item)
	assert(i != -1)
	remove_item(i, slot)


# Visualize item's image and quantity
class ItemStack extends TextureRect:
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

# Manage drag and drop
class Slot extends Panel:
	const Item = preload("res://src/items/item.gd")
	var item:Item
	var stack
	var inventory

	func _init(inv, _item = null):
		inventory = inv
		stack = ItemStack.new()
		stack.set_name("stack")
		add_child(stack)
		set_item(_item)
		set_custom_minimum_size(ITEM_SIZE)

	func set_item(i):
		item = i
		if item != null:
			set_theme(preload("res://data/themes/inventory/slot_full.tres"))
			set_name(item.name)
		else:
			set_theme(preload("res://data/themes/inventory/slot_empty.tres"))
			var columns = inventory.get_node("items").get_columns()
			set_name(str(get_index() % columns, '|', int(get_index() / columns)))
		stack.layout(item)

	func get_drag_data(pos):
		if item != null:
			var preview = ItemStack.new()
			preview.layout(item)
			set_drag_preview(preview)
			var ret_item = item
			inventory.erase_item(item, self)
			inventory.dragging = {'item': ret_item, 'slot': self, 'in_flight': true}
			return inventory.dragging

	func can_drop_data(pos, data):
		return item == null or (data.item != item and data.item.name == item.name and data.item.quantity + item.quantity <= data.item.max_quantity)

	func drop_data(pos, data):
		data.in_flight = false
		inventory.add_item(data.item, self) # take this item
		inventory.dragging = null
