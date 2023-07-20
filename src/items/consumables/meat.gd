class_name Meat
extends Consumable


var stamina


func _init(_name, _icon, _quantity, _stamina):
	super(_name, _icon, _quantity, 10, 50)
	stamina = _stamina


func effect(target: Player):
	if target.stamina_max < target.MAX_STAMINA and target.is_idle():
		target.stamina_max_increase(stamina)
		target.state_machine.travel("eat")
		return true
	return false


func clone():
	return get_script().new(name, icon, quantity, stamina)
