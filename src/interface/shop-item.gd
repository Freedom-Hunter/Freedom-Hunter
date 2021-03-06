extends HBoxContainer

const Item = preload("res://src/items/usable_item.gd")

var item: Item
var item_cost := 1000
var amount := 0
var time := 0

signal buy(item, cost)


func _ready():
	pass


func _process(delta):
	if amount != 0:
		time += delta
		if time > 0.2:
			$Quantity.value = $Quantity.value + amount
			time = 0


func set_item(new_item: Item, new_cost_factor: float):
	item = new_item
	item_cost = (100 - item.rarity) * new_cost_factor
	$Icon.texture = item.icon
	$Name.text = item.name
	($Quantity as Range).value = 0
	($Quantity as Range).max_value = item.max_quantity
	($QuantityLabel as Label).text = "0"
	($Cost as Label).text = "%d£" % item_cost


func _on_Reduce_button_down():
	amount = -1
	time = 1


func _on_Reduce_button_up():
	amount = 0


func _on_Increase_button_down():
	amount = 1
	time = 1


func _on_Increase_button_up():
	amount = 0


func _on_Buy_pressed():
	var player_item = item.clone()
	player_item.quantity = $Quantity.value
	print("Buy %s x%d for %d£" % [$Name.text, $Quantity.value, item_cost])
	emit_signal("buy", player_item, item_cost)


func _on_Quantity_value_changed(value):
	$QuantityLabel.text = str(value)
