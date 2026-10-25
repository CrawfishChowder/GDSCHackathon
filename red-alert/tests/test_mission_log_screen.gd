extends SceneTree


func _fail(reason: String) -> void:
	print("FAIL: " + reason)
	quit(1)


func _find_labels(node: Node, result: Array) -> void:
	if node is Label:
		result.append(node)
	for child in node.get_children():
		_find_labels(child, result)


func _initialize() -> void:
	await process_frame

	var ml: Node = root.get_node_or_null("MissionLog")
	if ml == null:
		var script_res := load("res://scripts/systems/mission_log.gd") as GDScript
		if script_res == null:
			return _fail("Failed to load mission_log.gd")
		ml = script_res.new()
		ml.name = "MissionLog"
		root.add_child(ml)
		await process_frame

	ml.call("record_death", "o2", "mistake", "test")

	var screen_script := load("res://scripts/ui/mission_log_screen.gd") as GDScript
	if screen_script == null:
		return _fail("Failed to load mission_log_screen.gd")

	var screen: Node = screen_script.new()
	if screen == null:
		return _fail("Failed to instantiate mission_log_screen")
	root.add_child(screen)
	await process_frame

	var count: int = int(screen.call("entry_count_shown"))
	if count < 1:
		return _fail("expected entry_count_shown() >= 1, got %d" % count)

	var labels: Array = []
	_find_labels(screen, labels)
	var found_soyuz: bool = false
	for lbl_node: Variant in labels:
		if lbl_node is Label and ("Soyuz 11" in (lbl_node as Label).text or "Apollo 13" in (lbl_node as Label).text):
			found_soyuz = true
			break

	if not found_soyuz:
		return _fail("no Label naming an O2 incident found in MissionLogScreen")

	var got := {}
	screen.connect("closed", func() -> void: got["closed"] = true)
	var back_btn: Button = screen.find_child("BackButton", true, false) as Button
	if back_btn == null:
		return _fail("BackButton not found")
	back_btn.emit_signal("pressed")
	if not got.get("closed", false):
		return _fail("Back button did not emit closed signal")

	screen.queue_free()
	print("PASS")
	quit(0)
