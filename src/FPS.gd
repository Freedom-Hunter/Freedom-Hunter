extends Label

func _ready():
	set_fixed_process(true)

func _fixed_process(delta):
	set_text("FPS: " + str(Performance.get_monitor(Performance.TIME_FPS)))
