extends "item.gd"

var stamina

func _init(pla, ico, nam, qua, sta).(pla, ico, nam, qua, 10, true, 50):
	stamina = sta

func effect():
	if player.max_stamina < player.MAX_STAMINA:
		player.increase_max_stamina(stamina)
		player.audio_node.play("potion_drink")
		return true
	return false

func clone():
	return get_script().new(player, icon, name, quantity, stamina)
