extends SceneTree


func _fail(reason: String) -> void:
	print("FAIL: " + reason)
	quit(1)


func _initialize() -> void:
	await process_frame

	var scene_res := load("res://scenes/minigames/dust_storm_power.tscn") as PackedScene
	if scene_res == null:
		return _fail("Failed to load dust_storm_power.tscn")

	# Test 1: Set 45/25/15 and engage -> completed
	var mg1: Node = scene_res.instantiate()
	if mg1 == null:
		return _fail("Failed to instantiate mg1")
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

	mg1.call("set_allocation", 0, 45)
	mg1.call("set_allocation", 1, 25)
	mg1.call("set_allocation", 2, 15)
	mg1.call("engage")
	await process_frame

	if not got1["completed"]:
		return _fail("expected mg1 to complete with 45/25/15, failed=%s reason='%s'" % [str(got1["failed"]), got1["reason"]])
	if got1["failed"]:
		return _fail("mg1 emitted failed when 45/25/15 is valid")

	mg1.queue_free()
	await process_frame

	# Test 2: New instance, left at default 33/33/33 -> engage fails with over-budget reason
	var mg2: Node = scene_res.instantiate()
	if mg2 == null:
		return _fail("Failed to instantiate mg2")
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

	mg2.call("engage")
	await process_frame

	if not got2["failed"]:
		return _fail("expected mg2 to fail at default 33/33/33 (99 total)")
	if got2["completed"]:
		return _fail("mg2 emitted completed when over budget")
	var r2: String = String(got2["reason"]).to_lower()
	if not ("batteries" in r2 or "power" in r2 or "panels" in r2 or "budget" in r2):
		return _fail("expected over-budget failure reason, got '%s'" % got2["reason"])

	mg2.queue_free()
	await process_frame

	# Test 3: New instance with 30/30/30 -> fails with life-support reason
	var mg3: Node = scene_res.instantiate()
	if mg3 == null:
		return _fail("Failed to instantiate mg3")
	root.add_child(mg3)
	await process_frame

	var got3 := {"completed": false, "failed": false, "reason": ""}
	mg3.connect("completed", func() -> void:
		got3["completed"] = true
	)
	mg3.connect("failed", func(reason: String) -> void:
		got3["failed"] = true
		got3["reason"] = reason
	)

	mg3.call("set_allocation", 0, 30)
	mg3.call("set_allocation", 1, 30)
	mg3.call("set_allocation", 2, 30)
	mg3.call("engage")
	await process_frame

	if not got3["failed"]:
		return _fail("expected mg3 to fail with 30/30/30 (life support < 40)")
	if got3["completed"]:
		return _fail("mg3 emitted completed with low life support")
	var r3: String = String(got3["reason"]).to_lower()
	if not ("life support" in r3 or "air" in r3):
		return _fail("expected life-support failure reason, got '%s'" % got3["reason"])

	mg3.queue_free()
	await process_frame

	print("PASS")
	quit(0)
