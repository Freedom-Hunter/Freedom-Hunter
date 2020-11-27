extends Label


func _physics_process(_delta):
	set_text("FPS: " + str(Performance.get_monitor(Performance.TIME_FPS)))
