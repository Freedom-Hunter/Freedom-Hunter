# SPDX-FileCopyrightText: 2023 Elia Argentieri
#
# SPDX-License-Identifier: GPL-3.0-or-later

extends PanelContainer

const ShopItemScene = preload("res://data/scenes/interface/items/shop-item.tscn")

var items := []
var shop_items := []


func set_items(items, cost_factor):
	self.items = items
	shop_items = []
	for child in $ScrollContainer/VBoxContainer.get_children():
		$ScrollContainer/VBoxContainer.remove_child(child)
	for item in items:
		var item_shop = ShopItemScene.instantiate()
		var actual_item_shop := item_shop.get_node("MarginContainer/HBoxContainer")
		actual_item_shop.set_item(item, cost_factor)
		$ScrollContainer/VBoxContainer.add_child(item_shop)
		shop_items.append(actual_item_shop)
