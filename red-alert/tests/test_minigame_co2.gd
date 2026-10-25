extends SceneTree


func _fail(reason: String) -> void:
	print("FAIL: " + reason)
	quit(1)


func _initialize() -> void:
	await process_frame

	var scene := load("res://scenes/minigames/co2_adapter.tscn") as PackedScene
	if scene == null:
		return _fail("Failed to load co2_adapter.tscn")

	# Test 1: Success path (press steps 0, 1, 2, 3)
	var mg1: Node = scene.instantiate()
	if mg1 == null:
		return _fail("Failed to instantiate co2_adapter scene (instance 1)")

	root.add_child(mg1)
	await process_frame

	var got1 := {"completed": false, "failed": false}
	mg1.connect("completed", func() -> void:
		got1["completed"] = true
	)
	mg1.connect("failed", func(_reason: String) -> void:
		got1["failed"] = true
	)

	var order: Variant = mg1.get("order")
	if not order is Array or order.size() != 4:
		return _fail("order should be an Array of 4 integers")
	if order == [0, 1, 2, 3]:
		return _fail("order must differ from [0, 1, 2, 3]")

	mg1.call("press_step", 0)
	mg1.call("press_step", 1)
	mg1.call("press_step", 2)
	mg1.call("press_step", 3)

	await process_frame

	if not got1["completed"]:
		return _fail("Instance 1 did not emit completed after steps 0, 1, 2, 3")
	if got1["failed"]:
		return _fail("Instance 1 emitted failed unexpectedly")

	mg1.free()
	await process_frame

	# Test 2: Failure path (press steps 0 then 2)
	var mg2: Node = scene.instantiate()
	if mg2 == null:
		return _fail("Failed to instantiate co2_adapter scene (instance 2)")

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

	mg2.call("press_step", 0)
	mg2.call("press_step", 2)

	await process_frame

	if not got2["failed"]:
		return _fail("Instance 2 did not emit failed after pressing 0 then 2")
	if got2["completed"]:
		return _fail("Instance 2 emitted completed unexpectedly")
	if not got2["reason"].contains("adapter leaked"):
		return _fail("Failure reason did not match expected message: %s" % got2["reason"])

	mg2.free()
	await process_frame

	print("PASS")
	quit(0)
