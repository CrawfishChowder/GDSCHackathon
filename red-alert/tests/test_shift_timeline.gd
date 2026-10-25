extends SceneTree


func _fail(reason: String) -> void:
	paused = false
	print("FAIL: " + reason)
	quit(1)


func _initialize() -> void:
	await process_frame

	var mm_script := load("res://scripts/systems/malfunction_manager.gd") as GDScript
	if mm_script == null:
		return _fail("Failed to load malfunction_manager.gd")

	var m: Node = mm_script.new()
	if m == null:
		return _fail("Failed to instantiate malfunction manager")

	# Step 1: start_run(), trigger("o2"), set survived_seconds = 30, fix("o2")
	m.start_run()
	m.trigger("o2")
	m.set("survived_seconds", 30.0)
	m.fix("o2")

	var hist_raw: Variant = m.get("history")
	if not (hist_raw is Array):
		return _fail("history is not an Array")
	var hist: Array = hist_raw as Array
	if hist.size() != 1:
		return _fail("Expected history size 1, got %d" % hist.size())

	var r0: Dictionary = hist[0]
	var out0: String = String(r0.get("outcome", ""))
	if out0 != "fixed":
		return _fail("Expected first record outcome 'fixed', got '%s'" % out0)
	var end0: float = float(r0.get("end", 0.0))
	if not is_equal_approx(end0, 30.0):
		return _fail("Expected first record end 30, got %s" % str(end0))

	# Step 2: trigger("reactor") and kill("reactor", "mistake"), assert last outcome is "fatal"
	m.trigger("reactor")
	m.kill("reactor", "mistake")

	if hist.size() != 2:
		return _fail("Expected history size 2, got %d" % hist.size())

	var r1: Dictionary = hist[1]
	var out1: String = String(r1.get("outcome", ""))
	if out1 != "fatal":
		return _fail("Expected last record outcome 'fatal', got '%s'" % out1)

	# Step 3: Practice mode append test
	m.mode = "practice"
	m.start_run()
	var reset_hist: Array = m.get("history") as Array
	if not reset_hist.is_empty():
		return _fail("Expected history to be reset on start_run()")

	m.trigger("co2")
	m.kill("co2", "mistake")
	var p_hist: Array = m.get("history") as Array
	if p_hist.size() != 2:
		return _fail("Expected practice history size 2, got %d" % p_hist.size())
	var p_last: Dictionary = p_hist[1]
	if String(p_last.get("outcome", "")) != "practice_mistake":
		return _fail("Expected practice note outcome 'practice_mistake', got '%s'" % String(p_last.get("outcome", "")))

	# Step 4: UI timeline formatting tests
	var sc_script := load("res://scripts/ui/shift_complete.gd") as GDScript
	if sc_script == null:
		return _fail("Failed to load shift_complete.gd")
	var sc: Node = sc_script.new()
	var test_lines: PackedStringArray = sc._format_timeline(hist)
	if test_lines.size() != 2:
		return _fail("Expected 2 formatted lines from shift_complete, got %d" % test_lines.size())
	if not test_lines[0].begins_with("0:00") or not test_lines[0].ends_with("fixed in 30s"):
		return _fail("Unexpected formatted line 0: %s" % test_lines[0])
	if not test_lines[1].ends_with("FATAL"):
		return _fail("Unexpected formatted line 1: %s" % test_lines[1])
	sc.free()

	var go_script := load("res://scripts/ui/game_over.gd") as GDScript
	if go_script == null:
		return _fail("Failed to load game_over.gd")
	var go: Node = go_script.new()
	var go_lines: PackedStringArray = go._format_timeline(p_hist)
	if go_lines.size() != 2:
		return _fail("Expected 2 formatted lines from game_over, got %d" % go_lines.size())
	if not go_lines[1].ends_with("practice mistake"):
		return _fail("Unexpected formatted line 1: %s" % go_lines[1])
	go.free()
	m.free()

	paused = false
	print("PASS")
	quit(0)
