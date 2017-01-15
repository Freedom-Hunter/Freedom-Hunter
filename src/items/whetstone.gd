extends "item.gd"

var sharp

func _init(pla, ico, nam, qua, sha).(pla, ico, nam, qua, 10, true, 50):
	sharp = sha

func effect():
	if player.equipment.weapon != null and not player.equipment.weapon.is_sharpened():
		player.equipment.weapon.sharpen(sharp)
		player.animation_node.play("whetstone")
		player.audio_node.play("whetstone")
		return true
	return false

func clone():
	return get_script().new(player, icon, name, quantity, sharp)
