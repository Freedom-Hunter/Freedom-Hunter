extends VBoxContainer


func _on_hp_changed(hp, hp_reg, hp_max):
	var size = 300 * hp_max / 50

	$hp/bar.max_value = hp_max
	$hp/bar.rect_min_size.x = size
	$hp/bar.rect_size.x = size
	$hp/bar.value = hp

	$hp/bar/red.max_value = hp_max
	$hp/bar/red.rect_min_size.x = size
	$hp/bar/red.rect_size.x = size
	$hp/bar/red.value = hp_reg

	$hp/label.text = "%d/%d" % [hp, hp_max]

func _on_stamina_changed(stamina, stamina_max):
	var size = 300 * stamina_max / 50

	$stamina/bar.max_value = stamina_max
	$stamina/bar.value = stamina
	$stamina/bar.rect_min_size.x = size
	$stamina/bar.rect_size.x = size

	$stamina/label.text = "%d/%d" % [stamina, stamina_max]
