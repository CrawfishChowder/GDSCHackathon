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
		root.add_child(mm)
		await process_frame

	var room_scene := load("res://scenes/stage1/stage_1_room.tscn") as PackedScene
	if room_scene == null:
		return _fail("Failed to load stage_1_room.tscn")

	var room: Node = room_scene.instantiate()
	root.add_child(room)

	await process_frame
	await process_frame

	if not bool(mm.get("running")):
		mm.call("start_run")

	var sign_power: Node = room.get_node_or_null("Polish/StationSignage/Sign_power")
	var sign_reactor: Node = room.get_node_or_null("Polish/StationSignage/Sign_reactor")
	var sign_o2: Node = room.get_node_or_null("Polish/StationSignage/Sign_o2")
	var sign_systems: Node = room.get_node_or_null("Polish/StationSignage/Sign_systems")
	if sign_power == null or sign_reactor == null or sign_o2 == null or sign_systems == null:
		return _fail("One or more static signs not found under Polish/StationSignage")

	var cue_power: Node = room.get_node_or_null("Polish/StationSignage/Cue_power")
	var cue_o2: Node = room.get_node_or_null("Polish/StationSignage/Cue_o2")
	var cue_reactor: Node = room.get_node_or_null("Polish/StationSignage/Cue_reactor")
	if cue_power == null or cue_o2 == null or cue_reactor == null:
		return _fail("One or more cues not found under Polish/StationSignage")

	if cue_power.get("visible") or cue_o2.get("visible") or cue_reactor.get("visible"):
		return _fail("Cues should initially be hidden")

	mm.call("trigger", "power")
	await create_timer(0.2).timeout

	if not bool(cue_power.get("visible")):
		return _fail("Polish/StationSignage/Cue_power is not visible after trigger('power')")

	if bool(cue_o2.get("visible")):
		return _fail("Polish/StationSignage/Cue_o2 is visible but should be hidden")

	if bool(cue_reactor.get("visible")):
		return _fail("Polish/StationSignage/Cue_reactor is visible but should be hidden")

	mm.call("fix", "power")
	await create_timer(0.2).timeout

	if bool(cue_power.get("visible")):
		return _fail("Polish/StationSignage/Cue_power is visible but should be hidden after fix('power')")

	print("PASS")
	quit(0)
