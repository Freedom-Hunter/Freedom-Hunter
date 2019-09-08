extends Control


const SCROLL_SPEED: float = 50.0
var time: float = 0


func _ready():
	set_process(false)
	$richtext.get_v_scroll().connect("scrolling", self, "set_process", [false])


func show():
	.show()
	time = 0
	set_process(true)


func hide():
	.hide()
	set_process(false)


func _process(delta):
	time += delta
	var v_scroll_value = time * SCROLL_SPEED
	var v_scroll = $richtext.get_v_scroll()
	v_scroll.value = v_scroll_value
	if v_scroll.page + v_scroll_value > v_scroll.max_value:
		set_process(false)
