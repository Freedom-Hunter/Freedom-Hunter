extends VBoxContainer

onready var global = get_node("/root/global")

func _process(delta):
	$hp.max_value = global.local_player.hp_max
	$hp.rect_size.x = 300 * global.local_player.hp_max / 50
	$hp.value = global.local_player.hp

	$hp/red_hp.max_value = global.local_player.hp_max
	$hp/red_hp.rect_size.x = $hp.rect_size.x
	$hp/red_hp.value = global.local_player.hp_regenerable

	$stamina.max_value = global.local_player.stamina_max
	$stamina.value = global.local_player.stamina
	$stamina.rect_size.x = 300 * global.local_player.stamina_max / 50

	$hp_label.text = "%d/%d" % [global.local_player.hp, global.local_player.hp_max]
	$stamina_label.text = "%d/%d" % [global.local_player.stamina, global.local_player.stamina_max]

