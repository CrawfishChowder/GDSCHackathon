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

	var demo_helper: Node = room.get_node_or_null("DemoHelper")
	if demo_helper == null:
		return _fail("DemoHelper node not found on room")

	mm.call("start_run")
	await process_frame

	# 1. Overlay hidden by default
	if bool(demo_helper.call("overlay_visible")):
		return _fail("expected overlay_visible() to be false initially")

	# 2. handle_key(KEY_F5) -> is_active("dust_storm")
	demo_helper.call("handle_key", KEY_F5)
	if not bool(mm.call("is_active", "dust_storm")):
		return _fail("expected dust_storm to be active after handle_key(KEY_F5)")

	# 3. handle_key(KEY_F12) -> overlay_visible()
	demo_helper.call("handle_key", KEY_F12)
	if not bool(demo_helper.call("overlay_visible")):
		return _fail("expected overlay_visible() to be true after handle_key(KEY_F12)")

	# Toggle off overlay
	demo_helper.call("handle_key", KEY_F12)
	if bool(demo_helper.call("overlay_visible")):
		return _fail("expected overlay_visible() to be false after second handle_key(KEY_F12)")

	# 4. F6 -> survived_seconds = SHIFT_LENGTH - 10
	demo_helper.call("handle_key", KEY_F6)
	var shift_len: float = float(mm.get("SHIFT_LENGTH")) if mm.get("SHIFT_LENGTH") != null else 300.0
	var survived: float = float(mm.get("survived_seconds"))
	if abs(survived - (shift_len - 10.0)) > 0.1:
		return _fail("expected survived_seconds to be %f, got %f" % [shift_len - 10.0, survived])

	# 5. F7 -> kill("reactor", "mistake", "Demo: instant failure.")
	demo_helper.call("handle_key", KEY_F7)
	if bool(mm.get("running")):
		return _fail("expected running to be false after F7 kill")
	if String(mm.get("death_kind")) != "mistake":
		return _fail("expected death_kind == 'mistake', got '%s'" % String(mm.get("death_kind")))
	if String(mm.get("death_detail")) != "Demo: instant failure.":
		return _fail("expected death_detail == 'Demo: instant failure.', got '%s'" % String(mm.get("death_detail")))

	# 6. F4 -> trigger("co2"). The F7 death opened GameOver, which pauses the tree,
	# and demo keys are (correctly) ignored while paused, so unpause first.
	paused = false
	mm.call("start_run")
	await process_frame
	demo_helper.call("handle_key", KEY_F4)
	if not bool(mm.call("is_active", "co2")):
		return _fail("expected co2 to be active after handle_key(KEY_F4)")

	paused = false
	print("PASS")
	quit(0)
