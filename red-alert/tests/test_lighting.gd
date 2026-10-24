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

	await process_frame
	await process_frame
	await process_frame

	var director: Node = room.get_node_or_null("Polish/LightingDirector")
	if director == null:
		return _fail("LightingDirector not found under Polish/LightingDirector")

	var count: int = int(director.call("light_count"))
	if count < 9:
		return _fail("Expected at least 9 lights, got %d" % count)

	mm.call("trigger", "power")
	await create_timer(1.5).timeout

	var avg_power: float = float(director.call("average_multiplier"))
	if not (avg_power < 0.5):
		return _fail("Expected average_multiplier < 0.5 during power failure, got %f" % avg_power)

	mm.call("fix", "power")
	await create_timer(1.5).timeout

	var avg_fixed: float = float(director.call("average_multiplier"))
	if not (avg_fixed > 0.8):
		return _fail("Expected average_multiplier > 0.8 after fixing power, got %f" % avg_fixed)

	print("PASS")
	quit(0)
