extends SceneTree

# Returning to the title screen must stop the run, so no failures fire behind the menu.


func _initialize() -> void:
	await process_frame
	var mm: Node = root.get_node("MalfunctionManager")
	mm.start_run()
	mm.trigger("o2")
	change_scene_to_file("res://scenes/ui/title_screen.tscn")
	for i in 3:
		await process_frame
	if mm.running or mm.active_id != "":
		print("FAIL: run still active behind the title screen")
		quit(1)
		return
	print("PASS")
	quit(0)
