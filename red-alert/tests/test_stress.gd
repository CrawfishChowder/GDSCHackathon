extends SceneTree


func _fail(reason: String) -> void:
	print("FAIL: " + reason)
	quit(1)


func _initialize() -> void:
	await process_frame

	var mm: Node = root.get_node_or_null("MalfunctionManager")
	if mm == null:
		var mm_script := load("res://scripts/systems/malfunction_manager.gd") as GDScript
		if mm_script == null:
			return _fail("Failed to load malfunction_manager.gd")
		mm = mm_script.new()
		root.add_child(mm)
		await process_frame

	var stress: Node = root.get_node_or_null("Stress")
	if stress == null:
		var stress_script := load("res://scripts/systems/stress.gd") as GDScript
		if stress_script == null:
			return _fail("Failed to load stress.gd")
		stress = stress_script.new()
		root.add_child(stress)
		await process_frame

	# 1. start_run()
	mm.call("start_run")
	await process_frame

	var hr: float = float(stress.get("heart_rate"))
	if hr != 72.0:
		return _fail("Expected heart_rate == 72 after start_run, got %f" % hr)

	# 2. trigger("reactor") and set time_left = 5
	mm.call("trigger", "reactor")
	mm.set("time_left", 5.0)

	# 3. wait 3 s
	await create_timer(3.1).timeout
	await process_frame

	# 4. Assert heart_rate > 90
	hr = float(stress.get("heart_rate"))
	if not (hr > 90.0):
		return _fail("Expected heart_rate > 90, got %f" % hr)

	# 5. Set external_heart_rate = 150 and wait a frame: assert heart_rate == 150
	stress.set("external_heart_rate", 150.0)
	await process_frame

	hr = float(stress.get("heart_rate"))
	if hr != 150.0:
		return _fail("Expected heart_rate == 150, got %f" % hr)

	# 6. Reset it to -1
	stress.set("external_heart_rate", -1.0)
	await process_frame

	var ext: float = float(stress.get("external_heart_rate"))
	if ext != -1.0:
		return _fail("Expected external_heart_rate == -1, got %f" % ext)

	# Stop run before quitting
	mm.call("stop_run")

	print("PASS")
	quit(0)
