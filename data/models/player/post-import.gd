tool # needed so it runs in editor
extends EditorScenePostImport

func post_import(scene):
	scene.get_node("AnimationPlayer").set_name("entity_animation")
	return scene # remember to return the imported scene
