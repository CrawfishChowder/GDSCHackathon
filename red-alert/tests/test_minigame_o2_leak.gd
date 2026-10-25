extends SceneTree

## Unit test for O2LeakSeal minigame.
## Tests both success and failure paths, checking signals and failure messages.


func _fail(reason: String) -> void:
	paused = false
	print("FAIL: " + reason)
	quit(1)


func _initialize() -> void:
	await process_frame

	var scene := load("res://scenes/minigames/o2_leak_seal.tscn") as PackedScene
	if scene == null:
		return _fail("Failed to load o2_leak_seal.tscn")

	# Test 1: Success path
	var mg1: Node = scene.instantiate()
	if mg1 == null:
		return _fail("Failed to instantiate o2_leak_seal scene (instance 1)")

	root.add_child(mg1)
	await process_frame

	var got1 := {"completed": false, "failed": false, "reason": ""}
	mg1.connect("completed", func() -> void:
		got1["completed"] = true
	)
	mg1.connect("failed", func(reason: String) -> void:
		got1["failed"] = true
		got1["reason"] = reason
	)

	var leak_idx1: int = int(mg1.get("leak_index"))
	if leak_idx1 < 0 or leak_idx1 > 8:
		return _fail("leak_index out of bounds: %d" % leak_idx1)

	var raw_pressures: Variant = mg1.get("pressures")
	if not (raw_pressures is Array) or (raw_pressures as Array).size() != 9:
		return _fail("pressures should be an Array of 9 floats")

	var arr1: Array = raw_pressures as Array
	var leak_val: float = float(arr1[leak_idx1])
	for i in range(9):
		var val: float = float(arr1[i])
		if i == leak_idx1:
			if val < 80.0 or val > 91.0:
				return _fail("Leak pressure out of range: %f" % val)
		else:
			if val < 98.0 or val > 103.0:
				return _fail("Healthy pressure out of range: %f" % val)
			if val <= leak_val:
				return _fail("Healthy joint %d not higher than leak: %f <= %f" % [i, val, leak_val])

	mg1.call("seal", leak_idx1)
	await process_frame

	if not got1["completed"]:
		return _fail("Instance 1 did not emit completed after sealing leak_index")
	if got1["failed"]:
		return _fail("Instance 1 emitted failed unexpectedly")

	mg1.free()
	await process_frame

	# Test 2: Failure path on a fresh instance
	var mg2: Node = scene.instantiate()
	if mg2 == null:
		return _fail("Failed to instantiate o2_leak_seal scene (instance 2)")

	root.add_child(mg2)
	await process_frame

	var got2 := {"completed": false, "failed": false, "reason": ""}
	mg2.connect("completed", func() -> void:
		got2["completed"] = true
	)
	mg2.connect("failed", func(reason: String) -> void:
		got2["failed"] = true
		got2["reason"] = reason
	)

	var leak_idx2: int = int(mg2.get("leak_index"))
	var wrong_idx: int = (leak_idx2 + 1) % 9

	mg2.call("seal", wrong_idx)
	await process_frame

	if not got2["failed"]:
		return _fail("Instance 2 did not emit failed after sealing wrong joint")
	if got2["completed"]:
		return _fail("Instance 2 emitted completed unexpectedly")

	var expected_reason: String = "You sealed a healthy joint and vented the oxygen line instead."
	if got2["reason"] != expected_reason:
		return _fail("Failure reason did not match expected message: %s" % got2["reason"])

	mg2.free()
	await process_frame

	# Test 3: Leak pressure drops over time
	var mg3: Node = scene.instantiate()
	if mg3 == null:
		return _fail("Failed to instantiate o2_leak_seal scene (instance 3)")

	root.add_child(mg3)
	await process_frame

	var leak_idx3: int = int(mg3.get("leak_index"))
	var arr3: Array = mg3.get("pressures") as Array
	var p_before: float = float(arr3[leak_idx3])

	mg3.call("_process", 0.5)

	var p_after: float = float(arr3[leak_idx3])
	if p_after >= p_before:
		return _fail("Leak pressure did not drop over time: before %f, after %f" % [p_before, p_after])

	mg3.free()
	await process_frame

	# Test 4: Keyboard shortcut triggers seal
	var mg4: Node = scene.instantiate()
	if mg4 == null:
		return _fail("Failed to instantiate o2_leak_seal scene (instance 4)")

	root.add_child(mg4)
	await process_frame

	var got4 := {"completed": false, "failed": false}
	mg4.connect("completed", func() -> void:
		got4["completed"] = true
	)

	var leak_idx4: int = int(mg4.get("leak_index"))
	var key_event := InputEventKey.new()
	key_event.pressed = true
	key_event.keycode = KEY_1 + leak_idx4
	mg4.call("_unhandled_input", key_event)
	await process_frame

	if not got4["completed"]:
		return _fail("Keyboard input KEY_%d did not trigger complete" % (leak_idx4 + 1))

	mg4.free()
	await process_frame

	paused = false
	print("PASS")
	quit(0)
