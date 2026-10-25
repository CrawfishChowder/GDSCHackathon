extends SceneTree


func _fail(reason: String) -> void:
	print("FAIL: " + reason)
	quit(1)


func _initialize() -> void:
	await process_frame

	var mm_script := load("res://scripts/systems/malfunction_manager.gd") as GDScript
	if mm_script == null:
		return _fail("Failed to load malfunction_manager.gd")

	var mm: Node = mm_script.new()
	if mm == null:
		return _fail("Failed to instantiate malfunction_manager")
	root.add_child(mm)
	await process_frame

	# 1. display_name("dust_storm") == "Dust storm"
	var name_res: String = String(mm.call("display_name", "dust_storm"))
	if name_res != "Dust storm":
		return _fail("expected display_name('dust_storm') == 'Dust storm', got '%s'" % name_res)

	# 2. trigger o2, set time_left = 5, fix("o2") -> close_calls == 1
	mm.call("start_run")
	mm.call("trigger", "o2")
	if String(mm.get("active_id")) != "o2":
		return _fail("expected active_id == 'o2' after trigger")

	mm.set("time_left", 5.0)
	mm.call("fix", "o2")

	var close_calls: int = int(mm.get("close_calls"))
	if close_calls != 1:
		return _fail("expected close_calls == 1, got %d" % close_calls)

	# 3. practice kill("o2", "mistake") -> practice_mistakes == 1
	mm.set("mode", "practice")
	mm.call("trigger", "o2")
	if String(mm.get("active_id")) != "o2":
		return _fail("expected active_id == 'o2' before practice mistake")

	mm.call("kill", "o2", "mistake")

	var practice_mistakes: int = int(mm.get("practice_mistakes"))
	if practice_mistakes != 1:
		return _fail("expected practice_mistakes == 1, got %d" % practice_mistakes)

	# 4. start_run() resets both to 0
	mm.call("start_run")
	close_calls = int(mm.get("close_calls"))
	practice_mistakes = int(mm.get("practice_mistakes"))
	if close_calls != 0:
		return _fail("expected close_calls == 0 after start_run, got %d" % close_calls)
	if practice_mistakes != 0:
		return _fail("expected practice_mistakes == 0 after start_run, got %d" % practice_mistakes)

	mm.queue_free()
	print("PASS")
	quit(0)
