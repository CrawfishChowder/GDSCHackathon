extends SceneTree

# Pressing "Start shift" on the title screen must load Stage 1 and start a run.


func _fail(reason: String) -> void:
	print("FAIL: " + reason)
	quit(1)


func _find_button(node: Node, text: String) -> Button:
	if node is Button and (node as Button).text.contains(text):
		return node
	for child in node.get_children():
		var found := _find_button(child, text)
		if found != null:
			return found
	return null


func _initialize() -> void:
	await process_frame
	change_scene_to_file("res://scenes/ui/title_screen.tscn")
	await process_frame
	await process_frame

	var start := _find_button(current_scene, "Start shift")
	if start == null:
		return _fail("no Start shift button on the title screen")
	start.pressed.emit()
	# The title fades to black (0.35 s) before changing scene.
	await create_timer(0.6).timeout
	for i in 3:
		await process_frame

	if current_scene == null or current_scene.name != "Stage1IndustrialRoom":
		return _fail("Start shift did not load the room (scene: %s)" % current_scene)
	var mm: Node = root.get_node("MalfunctionManager")
	if not mm.running or mm.mode != "normal":
		return _fail("run not started in normal mode")

	print("PASS")
	quit(0)
