# SPDX-FileCopyrightText: 2023 Elia Argentieri
#
# SPDX-License-Identifier: GPL-3.0-or-later

extends Label


func _physics_process(_delta):
	set_text("FPS: " + str(Performance.get_monitor(Performance.TIME_FPS)))
