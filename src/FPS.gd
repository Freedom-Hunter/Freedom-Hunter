extends Label

func _fixed_process(delta):
	set_text("FPS: " + str(Performance.get_monitor(Performance.TIME_FPS)))
