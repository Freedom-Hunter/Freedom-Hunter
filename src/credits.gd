# SPDX-FileCopyrightText: 2023 Elia Argentieri
#
# SPDX-License-Identifier: GPL-3.0-or-later

extends Control


const SCROLL_SPEED: float = 50.0
var time: float = 0


func _ready():
	set_process(false)
	var rich : RichTextLabel = $richtext
	rich.get_v_scroll_bar().connect("scrolling", Callable(self, "set_process").bind(false))


func my_show():
	super.show()
	time = 0
	set_process(true)


func my_hide():
	super.hide()
	set_process(false)


func _process(delta):
	time += delta
	var v_scroll_value = time * SCROLL_SPEED
	var v_scroll = $richtext.get_v_scroll()
	v_scroll.value = v_scroll_value
	if v_scroll.page + v_scroll_value > v_scroll.max_value:
		set_process(false)
