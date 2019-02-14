extends VBoxContainer

onready var global = get_node("/root/global")

func _process(delta):
	$hp/bar.max_value = global.local_player.hp_max
	$hp/bar.rect_size.x = 300 * global.local_player.hp_max / 50
	$hp/bar.value = global.local_player.hp

	$hp/bar/red.max_value = global.local_player.hp_max
	$hp/bar/red.rect_size.x = $hp/bar.rect_size.x
	$hp/bar/red.value = global.local_player.hp_regenerable

	$stamina/bar.max_value = global.local_player.stamina_max
	$stamina/bar.value = global.local_player.stamina
	$stamina/bar.rect_size.x = 300 * global.local_player.stamina_max / 50

	$hp/label.text = "%d/%d" % [global.local_player.hp, global.local_player.hp_max]
	$stamina/label.text = "%d/%d" % [global.local_player.stamina, global.local_player.stamina_max]

