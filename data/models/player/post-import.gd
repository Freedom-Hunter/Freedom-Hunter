tool # needed so it runs in editor
extends EditorScenePostImport

func post_import(scene):
	var player = scene.get_node("AnimationPlayer")
	player.set_name("entity_animation")
	player.autoplay = "idle"

	var add_audio = {"death": "head", "dodge": "head", "whetstone": "weapon_R"}
	for anim_name in add_audio:
		var anim = player.get_animation(anim_name)
		var track = anim.add_track(Animation.TYPE_AUDIO)
		anim.track_set_path(track, "Armature/Skeleton/%s/audio" % add_audio[anim_name])
		anim.audio_track_insert_key(track, 0, load("res://data/sounds/%s.wav" % anim_name))

	for anim_name in ["idle", "run", "walk"]:
		var anim = player.get_animation(anim_name)
		anim.loop = true

	return scene # remember to return the imported scene
