extends SceneTree


func _fail(reason: String) -> void:
	paused = false
	print("FAIL: " + reason)
	quit(1)


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

	if not bool(mm.get("running")):
		mm.call("start_run")

	mm.call("trigger", "power")
	await create_timer(0.2).timeout

	var event: Node = room.get_node_or_null("EventDirector/PowerFailureEvent")
	if event == null:
		return _fail("EventDirector/PowerFailureEvent node not found")
	if not bool(event.call("is_active")):
		return _fail("EventDirector/PowerFailureEvent.is_active() is false after trigger")

	var breaker: Node = room.get_node_or_null("WallFixtures/NorthDoorBreakerBox")
	if breaker == null:
		return _fail("WallFixtures/NorthDoorBreakerBox node not found")

	breaker.call("interact", null)
	breaker.call("toggle_main_breaker")
	breaker.call("toggle_main_breaker")
	await create_timer(0.2).timeout

	var active_id: String = String(mm.get("active_id"))
	if active_id != "":
		return _fail("expected active_id == '', got '%s'" % active_id)

	var fixes: int = int(mm.get("fixes_count"))
	if fixes != 1:
		return _fail("expected fixes_count == 1, got %d" % fixes)

	if bool(event.call("is_active")):
		return _fail("expected EventDirector/PowerFailureEvent to be inactive after fix")

	# Second trigger: assert flipping only OFF does not fix
	mm.call("trigger", "power")
	await create_timer(0.2).timeout

	if not bool(event.call("is_active")):
		return _fail("EventDirector/PowerFailureEvent is not active on second trigger")

	breaker.call("toggle_main_breaker")
	await create_timer(0.2).timeout

	if String(mm.get("active_id")) != "power":
		return _fail("expected active_id to still be 'power' after flipping only OFF")

	if not bool(event.call("is_active")):
		return _fail("expected EventDirector/PowerFailureEvent to still be active after flipping only OFF")

	paused = false
	print("PASS")
	quit(0)
