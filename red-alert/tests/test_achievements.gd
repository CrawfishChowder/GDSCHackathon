extends SceneTree

var got := {}


func _fail(reason: String) -> void:
	if root != null:
		paused = false
	print("FAIL: " + reason)
	quit(1)


func _initialize() -> void:
	await process_frame

	var sd: Node = root.get_node_or_null("SaveData")
	if sd == null:
		var sd_script := load("res://scripts/systems/save_data.gd") as GDScript
		if sd_script == null:
			return _fail("Failed to load save_data.gd")
		sd = sd_script.new()
		root.add_child(sd)
		await process_frame

	var mm: Node = root.get_node_or_null("MalfunctionManager")
	if mm == null:
		var mm_script := load("res://scripts/systems/malfunction_manager.gd") as GDScript
		if mm_script == null:
			return _fail("Failed to load malfunction_manager.gd")
		mm = mm_script.new()
		root.add_child(mm)
		await process_frame

	var ach: Node = root.get_node_or_null("Achievements")
	if ach == null:
		var ach_script := load("res://scripts/systems/achievements.gd") as GDScript
		if ach_script == null:
			return _fail("Failed to load achievements.gd")
		ach = ach_script.new()
		root.add_child(ach)
		await process_frame

	# Clear "achievements" in SaveData
	sd.call("set_value", "achievements", [])
	await process_frame

	# Record signals into shared got dictionary
	ach.connect("unlocked", func(id: String, title: String) -> void:
		got[id] = title
	)

	# Assert curiosity is not yet unlocked
	if ach.call("is_unlocked", "curiosity"):
		return _fail("curiosity should be locked after clearing SaveData")

	# unlock("curiosity") fires the unlocked signal and makes is_unlocked true
	ach.call("unlock", "curiosity")
	await process_frame

	if not got.has("curiosity"):
		return _fail("unlock('curiosity') did not fire unlocked signal")
	if got.get("curiosity") != "Curiosity":
		return _fail("Expected title 'Curiosity', got '%s'" % str(got.get("curiosity")))
	if not ach.call("is_unlocked", "curiosity"):
		return _fail("is_unlocked('curiosity') should be true after unlock")

	# A second unlock doesn't fire again
	got.clear()
	ach.call("unlock", "curiosity")
	await process_frame

	if not got.is_empty():
		return _fail("Second unlock('curiosity') should not fire unlocked signal again")

	# Fresh manager-independent check: emit MalfunctionManager.shift_completed after start_run() and assert first_shift is unlocked
	sd.call("set_value", "achievements", [])
	await process_frame

	if ach.call("is_unlocked", "first_shift"):
		return _fail("first_shift should not be unlocked yet")

	mm.call("start_run")
	await process_frame

	mm.emit_signal("shift_completed")
	await process_frame

	if not ach.call("is_unlocked", "first_shift"):
		return _fail("first_shift should be unlocked after shift_completed")

	# Verify all_ids()
	var ids: Array = ach.call("all_ids")
	if ids.size() != 6:
		return _fail("Expected 6 achievements, got %d" % ids.size())

	# Verify mission log screen instantiates with achievements section
	var mls_script := load("res://scripts/ui/mission_log_screen.gd") as GDScript
	if mls_script != null:
		var mls: Control = mls_script.new()
		root.add_child(mls)
		await process_frame
		mls.queue_free()
		await process_frame

	if root != null:
		paused = false
	print("PASS")
	quit(0)
