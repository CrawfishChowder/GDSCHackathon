extends SceneTree


func _fail(reason: String) -> void:
	print("FAIL: " + reason)
	quit(1)


func _initialize() -> void:
	await process_frame

	var mm: Node = root.get_node_or_null("MalfunctionManager")
	if mm == null:
		var mm_script := load("res://scripts/systems/malfunction_manager.gd") as GDScript
		if mm_script == null:
			return _fail("Failed to load malfunction_manager.gd")
		mm = mm_script.new()
		mm.name = "MalfunctionManager"
		root.add_child(mm)
		await process_frame

	var room_scene := load("res://scenes/stage1/stage_1_room.tscn") as PackedScene
	if room_scene == null:
		return _fail("Failed to load stage_1_room.tscn")

	var room: Node = room_scene.instantiate()
	root.add_child(room)

	# Wait 2 frames
	await process_frame
	await process_frame

	# Assert that MainConsole/ConsoleDisplays has 3 MonitorDisplay children
	var console_displays := room.get_node_or_null("MainConsole/ConsoleDisplays")
	if console_displays == null:
		return _fail("MainConsole/ConsoleDisplays node not found")

	var monitor_count: int = 0
	for child in console_displays.get_children():
		if child is MonitorDisplay or (child.get_script() != null and child.get_script().resource_path.ends_with("monitor_display.gd")):
			monitor_count += 1

	if monitor_count != 3:
		return _fail("Expected 3 MonitorDisplay children under ConsoleDisplays, found %d" % monitor_count)

	var center_display := console_displays.get_node_or_null("CenterDisplay")
	if center_display == null:
		return _fail("CenterDisplay node not found under ConsoleDisplays")

	# Trigger o2 and wait 0.5 s
	if not bool(mm.get("running")):
		mm.call("start_run")
	mm.call("trigger", "o2")

	await create_timer(0.5).timeout

	# Assert that some Label under CenterDisplay has text containing "O2"
	if not _has_label_with_text(center_display, "O2"):
		return _fail("No Label under CenterDisplay contains text 'O2'")

	# Also assert that BulkheadDoors/NorthBulkheadDoor/DoorDisplay exists
	var door_display := room.get_node_or_null("BulkheadDoors/NorthBulkheadDoor/DoorDisplay")
	if door_display == null:
		return _fail("BulkheadDoors/NorthBulkheadDoor/DoorDisplay node not found")

	print("PASS")
	quit(0)


func _has_label_with_text(node: Node, text: String) -> bool:
	if node is Label and text in (node as Label).text:
		return true
	for child in node.get_children():
		if _has_label_with_text(child, text):
			return true
	return false
