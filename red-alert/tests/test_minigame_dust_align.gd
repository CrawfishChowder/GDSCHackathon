extends SceneTree

var got := {}


func _fail(reason: String) -> void:
	if root != null:
		paused = false
	print("FAIL: " + reason)
	quit(1)


func _initialize() -> void:
	await process_frame

	var scene: PackedScene = load("res://scenes/minigames/dust_panel_align.tscn") as PackedScene
	if scene == null:
		return _fail("Failed to load scenes/minigames/dust_panel_align.tscn")

	# Test 1: set_array(sun_bearing + 3), then lock(), completes.
	got.clear()
	var mg: Node = scene.instantiate()
	if mg == null:
		return _fail("Failed to instantiate dust_panel_align")
	root.add_child(mg)
	await process_frame

	mg.connect("completed", func() -> void:
		got["completed"] = true
	)
	mg.connect("failed", func(reason: String) -> void:
		got["failed"] = reason
	)

	var bearing: int = int(mg.get("sun_bearing"))
	if bearing < 20 or bearing > 160:
		return _fail("sun_bearing %d is outside [20, 160]" % bearing)

	mg.call("set_array", bearing + 3)
	mg.call("lock")
	await process_frame

	if not bool(got.get("completed", false)):
		return _fail("set_array(sun_bearing + 3) did not complete")
	if got.has("failed"):
		return _fail("set_array(sun_bearing + 3) unexpectedly failed: %s" % str(got.get("failed")))

	mg.queue_free()
	await process_frame

	# Test 2: Fresh instance: set_array(sun_bearing + 20), then lock(), fails with expected reason.
	got.clear()
	var mg2: Node = scene.instantiate()
	if mg2 == null:
		return _fail("Failed to instantiate second dust_panel_align")
	root.add_child(mg2)
	await process_frame

	mg2.connect("completed", func() -> void:
		got["completed"] = true
	)
	mg2.connect("failed", func(reason: String) -> void:
		got["failed"] = reason
	)

	var bearing2: int = int(mg2.get("sun_bearing"))
	if bearing2 < 20 or bearing2 > 160:
		return _fail("sun_bearing %d is outside [20, 160]" % bearing2)

	mg2.call("set_array", bearing2 + 20)
	mg2.call("lock")
	await process_frame

	if not got.has("failed"):
		return _fail("set_array(sun_bearing + 20) did not fail")

	var expected_reason: String = "The array locked away from the sun and the batteries drained in the storm."
	var actual_reason: String = String(got.get("failed", ""))
	if actual_reason != expected_reason:
		return _fail("Expected fail reason '%s', got '%s'" % [expected_reason, actual_reason])

	if bool(got.get("completed", false)):
		return _fail("set_array(sun_bearing + 20) unexpectedly completed")

	mg2.queue_free()
	await process_frame

	# Test 3: Boundary check: set_array(sun_bearing - 5) completes.
	got.clear()
	var mg3: Node = scene.instantiate()
	if mg3 == null:
		return _fail("Failed to instantiate third dust_panel_align")
	root.add_child(mg3)
	await process_frame

	mg3.connect("completed", func() -> void:
		got["completed"] = true
	)
	mg3.connect("failed", func(reason: String) -> void:
		got["failed"] = reason
	)

	var bearing3: int = int(mg3.get("sun_bearing"))
	mg3.call("set_array", bearing3 - 5)
	mg3.call("lock")
	await process_frame

	if not bool(got.get("completed", false)):
		return _fail("set_array(sun_bearing - 5) boundary did not complete")

	mg3.queue_free()
	await process_frame

	if root != null:
		paused = false
	print("PASS")
	quit(0)
