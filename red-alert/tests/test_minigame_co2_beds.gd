extends SceneTree

var got: Dictionary = {}


func _fail(reason: String) -> void:
	paused = false
	print("FAIL: " + reason)
	quit(1)


func _initialize() -> void:
	await process_frame
	paused = false

	var scene := load("res://scenes/minigames/co2_beds.tscn") as PackedScene
	if scene == null:
		_fail("Failed to load co2_beds.tscn")
		return

	# --- Test 1: Choosing the valid bed completes ---
	var mg1: Node = scene.instantiate()
	if mg1 == null:
		_fail("Failed to instantiate co2_beds scene (instance 1)")
		return

	root.add_child(mg1)
	await process_frame

	got = {"completed": false, "failed": false, "reason": ""}
	mg1.connect("completed", func() -> void:
		got["completed"] = true
	)
	mg1.connect("failed", func(reason: String) -> void:
		got["failed"] = true
		got["reason"] = reason
	)

	var valid_idx1: int = int(mg1.get("valid_index"))
	var hot_idx1: int = int(mg1.get("hot_index"))
	var sat_idx1: int = int(mg1.get("saturated_index"))

	if valid_idx1 < 0 or valid_idx1 > 2:
		_fail("valid_index out of bounds: %d" % valid_idx1)
		return
	if hot_idx1 < 0 or hot_idx1 > 2:
		_fail("hot_index out of bounds: %d" % hot_idx1)
		return
	if sat_idx1 < 0 or sat_idx1 > 2:
		_fail("saturated_index out of bounds: %d" % sat_idx1)
		return
	if valid_idx1 == hot_idx1 or valid_idx1 == sat_idx1 or hot_idx1 == sat_idx1:
		_fail("Indices must all be distinct")
		return

	mg1.call("choose", valid_idx1)
	await process_frame

	if not bool(got["completed"]):
		_fail("Instance 1 did not emit completed after choosing valid bed")
		return
	if bool(got["failed"]):
		_fail("Instance 1 emitted failed unexpectedly")
		return

	mg1.free()
	await process_frame

	# --- Test 2: Choosing the hot bed fails with the hot reason ---
	var mg2: Node = scene.instantiate()
	if mg2 == null:
		_fail("Failed to instantiate co2_beds scene (instance 2)")
		return

	root.add_child(mg2)
	await process_frame

	got = {"completed": false, "failed": false, "reason": ""}
	mg2.connect("completed", func() -> void:
		got["completed"] = true
	)
	mg2.connect("failed", func(reason: String) -> void:
		got["failed"] = true
		got["reason"] = reason
	)

	var hot_idx2: int = int(mg2.get("hot_index"))
	mg2.call("choose", hot_idx2)
	await process_frame

	if not bool(got["failed"]):
		_fail("Instance 2 did not emit failed after choosing hot bed")
		return
	if bool(got["completed"]):
		_fail("Instance 2 emitted completed unexpectedly")
		return

	var expected_hot_reason: String = "You switched to a bed that was still venting hot carbon dioxide."
	var actual_hot_reason: String = String(got["reason"])
	if actual_hot_reason != expected_hot_reason:
		_fail("Hot bed reason mismatch: expected '%s', got '%s'" % [expected_hot_reason, actual_hot_reason])
		return

	mg2.free()
	await process_frame

	# --- Test 3: Choosing the saturated bed fails with the saturated reason ---
	var mg3: Node = scene.instantiate()
	if mg3 == null:
		_fail("Failed to instantiate co2_beds scene (instance 3)")
		return

	root.add_child(mg3)
	await process_frame

	got = {"completed": false, "failed": false, "reason": ""}
	mg3.connect("completed", func() -> void:
		got["completed"] = true
	)
	mg3.connect("failed", func(reason: String) -> void:
		got["failed"] = true
		got["reason"] = reason
	)

	var sat_idx3: int = int(mg3.get("saturated_index"))
	mg3.call("choose", sat_idx3)
	await process_frame

	if not bool(got["failed"]):
		_fail("Instance 3 did not emit failed after choosing saturated bed")
		return
	if bool(got["completed"]):
		_fail("Instance 3 emitted completed unexpectedly")
		return

	var expected_sat_reason: String = "You switched to a saturated bed and carbon dioxide kept rising."
	var actual_sat_reason: String = String(got["reason"])
	if actual_sat_reason != expected_sat_reason:
		_fail("Saturated bed reason mismatch: expected '%s', got '%s'" % [expected_sat_reason, actual_sat_reason])
		return

	mg3.free()
	await process_frame

	paused = false
	print("PASS")
	quit(0)
