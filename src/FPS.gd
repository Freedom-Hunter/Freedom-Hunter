extends Label

func _physics_process(delta):
	set_text("FPS: " + str(Performance.get_monitor(Performance.TIME_FPS)))
