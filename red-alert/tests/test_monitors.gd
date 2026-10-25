extends SceneTree

const MONITOR_IDS: Array[StringName] = [
	&"console_left",
	&"console_center",
	&"console_right",
	&"door_north",
	&"door_east",
	&"door_west",
]


func _fail(reason: String) -> void:
	print("FAIL: " + reason)
	quit(1)


func _initialize() -> void:
	await process_frame
	var room_scene := load("res://scenes/stage1/stage_1_room.tscn") as PackedScene
	if room_scene == null:
		return _fail("Failed to load stage_1_room.tscn")

	var room := room_scene.instantiate()
	root.add_child(room)
	await process_frame
	await process_frame

	var displays := room.get_node_or_null("NormalOperations")
	if displays == null:
		return _fail("NormalOperations service not found")
	if displays.call("get_monitor_ids") != MONITOR_IDS:
		return _fail("NormalOperations does not manage all six stable monitor IDs")
	if room.get_node_or_null("MainConsole/ConsoleDisplays") == null:
		return _fail("ConsoleDisplays controller not found")
	if _display_controllers_have_meshes(room):
		return _fail("Gameplay displays created duplicate physical monitor meshes")

	for monitor_id in MONITOR_IDS:
		if displays.call("is_monitor_claimed", monitor_id):
			return _fail("%s should begin on its default display" % monitor_id)
		var viewport := _viewport_for(displays, monitor_id)
		if viewport == null or viewport.get_child_count() != 1:
			return _fail("%s does not have one running default display" % monitor_id)

	var manager := root.get_node_or_null("MalfunctionManager")
	if manager == null:
		return _fail("MalfunctionManager autoload not found")
	manager.call("trigger", "o2")
	await create_timer(0.5).timeout

	for monitor_id in MONITOR_IDS:
		if not displays.call("is_monitor_claimed", monitor_id):
			return _fail("%s was not claimed for the emergency" % monitor_id)
		var viewport := _viewport_for(displays, monitor_id)
		if viewport.get_node_or_null("ActiveOverride") == null:
			return _fail("%s has no active override layer" % monitor_id)
		if viewport.get_child_count() != 2:
			return _fail("%s default did not remain behind its override" % monitor_id)

	var center := _viewport_for(displays, &"console_center")
	if not _has_label_with_text(center.get_node("ActiveOverride"), "O2"):
		return _fail("Center emergency display does not report the O2 event")

	manager.call("fix", "o2")
	await process_frame
	await process_frame
	for monitor_id in MONITOR_IDS:
		if displays.call("is_monitor_claimed", monitor_id):
			return _fail("%s did not restore its default after release" % monitor_id)
		if _viewport_for(displays, monitor_id).get_child_count() != 1:
			return _fail("%s override layer remained after release" % monitor_id)
	await _test_ownership_guards(displays)

	print("PASS")
	quit(0)


func _viewport_for(displays: Node, monitor_id: StringName) -> SubViewport:
	var name_parts := String(monitor_id).split("_", false)
	var viewport_name := ""
	for part in name_parts:
		viewport_name += part.capitalize()
	return displays.get_node_or_null("Displays/%sViewport" % viewport_name) as SubViewport


func _display_controllers_have_meshes(room: Node) -> bool:
	var controllers: Array[Node] = [room.get_node("MainConsole/ConsoleDisplays")]
	for direction in ["North", "East", "West"]:
		controllers.append(room.get_node(
			"BulkheadDoors/%sBulkheadDoor/DoorDisplay" % direction
		))
	for controller in controllers:
		if controller.find_children("*", "MeshInstance3D", true, false):
			return true
	return false


func _test_ownership_guards(displays: Node) -> void:
	var owner_one := Node.new()
	var owner_two := Node.new()
	root.add_child(owner_one)
	root.add_child(owner_two)
	var override := ColorRect.new()
	var override_scene := PackedScene.new()
	override_scene.pack(override)
	override.free()
	if not displays.call("claim_monitor", &"console_center", owner_one, override_scene):
		return _fail("First override owner could not claim console_center")
	if displays.call("claim_monitor", &"console_center", owner_two, override_scene):
		return _fail("A second owner silently replaced the first override")
	owner_one.queue_free()
	await process_frame
	await process_frame
	if displays.call("is_monitor_claimed", &"console_center"):
		return _fail("Owner removal did not automatically restore the default")
	owner_two.queue_free()


func _has_label_with_text(node: Node, text: String) -> bool:
	if node is Label and text in (node as Label).text:
		return true
	for child in node.get_children():
		if _has_label_with_text(child, text):
			return true
	return false
