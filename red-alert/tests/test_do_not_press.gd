extends SceneTree


func _fail(reason: String) -> void:
	paused = false
	print("FAIL: " + reason)
	quit(1)


func _initialize() -> void:
	# Autoload names are not identifiers in a --script main loop; look them up.
	var mm: Node = root.get_node("MalfunctionManager")
	var save_data: Node = root.get_node("SaveData")

	var room_scene := load("res://scenes/stage1/stage_1_room.tscn") as PackedScene
	if room_scene == null:
		return _fail("Failed to load stage_1_room.tscn")

	var room: Node = room_scene.instantiate()
	if room == null:
		return _fail("Failed to instantiate stage_1_room.tscn")

	root.add_child(room)
	await process_frame

	mm.start_run()

	var button: Node = room.get_node_or_null("WallFixtures/DoNotPressButton")
	if button == null:
		button = room.find_child("DoNotPressButton", true, false)
	if button == null:
		return _fail("DoNotPressButton node not found in room")

	var count_before: int = int(save_data.get_value("do_not_press_count", 0))

	button.interact(null)

	await create_timer(2.3, true).timeout

	var count_after: int = int(save_data.get_value("do_not_press_count", 0))
	if count_after != count_before + 1:
		return _fail("count did not increment by 1: before=%d, after=%d" % [count_before, count_after])

	if mm.death_kind != "button":
		return _fail("MalfunctionManager.death_kind expected 'button', got '%s'" % mm.death_kind)

	if mm.running:
		return _fail("MalfunctionManager.running expected false, got true")

	paused = false
	print("PASS")
	quit(0)
