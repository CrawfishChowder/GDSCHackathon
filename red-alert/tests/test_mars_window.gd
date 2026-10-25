extends SceneTree


func _fail(reason: String) -> void:
	paused = false
	print("FAIL: " + reason)
	quit(1)


func _pass() -> void:
	paused = false
	print("PASS")
	quit(0)


func _find_named_node(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	for child: Node in node.get_children():
		var found := _find_named_node(child, target_name)
		if found != null:
			return found
	return null


func _initialize() -> void:
	await process_frame

	var mm: Node = root.get_node_or_null("MalfunctionManager")
	if mm == null:
		return _fail("MalfunctionManager not found")

	var room_scene := load("res://scenes/stage1/stage_1_room.tscn") as PackedScene
	if room_scene == null:
		return _fail("Failed to load stage_1_room.tscn")

	var room: Node = room_scene.instantiate()
	if room == null:
		return _fail("Failed to instantiate stage_1_room.tscn")

	root.add_child(room)
	await process_frame
	await process_frame

	var mars_window: Node = _find_named_node(room, "MarsWindow")
	if mars_window == null:
		return _fail("MarsWindow not found in stage_1_room")

	var initial_level: float = float(mars_window.call("storm_level"))
	if initial_level > 0.1:
		return _fail("expected initial storm_level() <= 0.1, got %f" % initial_level)

	mm.call("trigger", "dust_storm")
	await create_timer(2.0).timeout

	var level: float = float(mars_window.call("storm_level"))
	if level <= 0.5:
		return _fail("expected storm_level() > 0.5 after dust_storm, got %f" % level)

	_pass()
