extends SceneTree

var got: Dictionary = {}


func _fail(reason: String) -> void:
	paused = false
	print("FAIL: " + reason)
	quit(1)


func _initialize() -> void:
	await process_frame

	var scene: PackedScene = load("res://scenes/minigames/reactor_valves.tscn") as PackedScene
	if scene == null:
		return _fail("Failed to load reactor_valves.tscn")

	# Part 1: Set all valves closed and step 0.1 s at a time until fail.
	var inst1: Node = scene.instantiate()
	if inst1 == null:
		return _fail("Failed to instantiate reactor_valves")

	root.add_child(inst1)
	await process_frame

	got["fail_reason"] = ""
	inst1.connect("failed", func(reason: String) -> void:
		got["fail_reason"] = reason
	)

	for i: int in range(3):
		inst1.call("set_valve", i, false)

	var failed: bool = false
	for _step: int in range(100):
		inst1.call("step_sim", 0.1)
		var reason: String = str(got.get("fail_reason", ""))
		if not reason.is_empty():
			failed = true
			break

	if not failed:
		inst1.queue_free()
		return _fail("Simulation did not fail with all valves closed")

	var expected_reason: String = "A coolant loop over-pressurized and ruptured. The core lost cooling."
	var actual_reason: String = str(got.get("fail_reason", ""))
	if actual_reason != expected_reason:
		inst1.queue_free()
		return _fail("Fail reason was '%s', expected '%s'" % [actual_reason, expected_reason])

	inst1.queue_free()
	await process_frame

	# Part 2: Fresh instance, alternate valves to hold the band, step up to 20 s.
	var inst2: Node = scene.instantiate()
	if inst2 == null:
		return _fail("Failed to instantiate second reactor_valves")

	root.add_child(inst2)
	await process_frame

	got["completed"] = false
	inst2.connect("completed", func() -> void:
		got["completed"] = true
	)

	var completed: bool = false
	var dt: float = 0.1
	var total_time: float = 0.0

	while total_time < 20.0:
		var raw_pressures: Variant = inst2.get("pressure")
		if not (raw_pressures is Array):
			inst2.queue_free()
			return _fail("Pressure property is not an Array")

		var pressures: Array = raw_pressures as Array
		if pressures.size() != 3:
			inst2.queue_free()
			return _fail("Pressure array size is not 3")

		for i: int in range(3):
			var p: float = float(pressures[i])
			if p > 60.0:
				inst2.call("set_valve", i, true)
			elif p < 50.0:
				inst2.call("set_valve", i, false)

		inst2.call("step_sim", dt)
		total_time += dt

		if bool(got.get("completed", false)):
			completed = true
			break

	if not completed:
		inst2.queue_free()
		return _fail("Simulation did not complete after %.1f seconds of balancing" % total_time)

	inst2.queue_free()
	await process_frame

	paused = false
	print("PASS")
	quit(0)
