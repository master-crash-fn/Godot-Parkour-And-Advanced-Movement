@tool
extends EditorScript

const FBX_FOLDER := "res://npc/fbx-animations/"
const OUTPUT_LIBRARY_PATH := "res://npc/animations/animlib.res"

func _run():
	print("🔄 Start met samenvoegen van animaties uit .fbx bestanden...")

	var dir := DirAccess.open(FBX_FOLDER)
	if dir == null:
		push_error("❌ Kan map niet openen: %s" % FBX_FOLDER)
		return

	var merged_library := AnimationLibrary.new()
	var added_animations := 0

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".fbx"):
			var fbx_path = FBX_FOLDER.path_join(file_name)
			if ResourceLoader.exists(fbx_path):
				var scene_resource := load(fbx_path)
				if scene_resource and scene_resource is PackedScene:
					var instance = scene_resource.instantiate()
					var anim_players := find_animation_players(instance)
					for anim_player in anim_players:
						for anim_name in anim_player.get_animation_list():
							var anim = anim_player.get_animation(anim_name)
							var new_name = "%s__%s" % [file_name.get_basename(), anim_name]
							if merged_library.has_animation(new_name):
								new_name += "_%s" % str(Time.get_ticks_usec() % 10000)
							merged_library.add_animation(new_name, anim)
							added_animations += 1
				else:
					push_warning("⚠️ Kon .fbx niet laden als scene: %s" % fbx_path)
			else:
				push_warning("⚠️ Bestand bestaat niet: %s" % fbx_path)
		file_name = dir.get_next()

	dir.list_dir_end()

	if added_animations > 0:
		var err := ResourceSaver.save(merged_library, OUTPUT_LIBRARY_PATH)
		if err == OK:
			print("✅ %d animaties samengevoegd in: %s" % [added_animations, OUTPUT_LIBRARY_PATH])
		else:
			push_error("❌ Fout bij opslaan van AnimationLibrary: %s" % OUTPUT_LIBRARY_PATH)
	else:
		print("⚠️ Geen animaties gevonden.")

func find_animation_players(root: Node) -> Array:
	var result := []
	if root is AnimationPlayer:
		result.append(root)
	for child in root.get_children():
		if child is Node:
			result += find_animation_players(child)
	return result
