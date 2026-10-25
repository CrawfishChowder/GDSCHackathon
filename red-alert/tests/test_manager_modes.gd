extends SceneTree


func _fail(reason: String) -> void:
	print("FAIL: " + reason)
	quit(1)


func _initialize() -> void:
	await process_frame

	var mgr_script := load("res://scripts/systems/malfunction_manager.gd")
	if mgr_script == null:
		return _fail("Failed to load malfunction_manager.gd")
	var mgr: Node = mgr_script.new()
	root.add_child(mgr)
	await process_frame

	# co2: display_name("co2") == "CO2 buildup"
	var name_co2: String = String(mgr.call("display_name", "co2"))
	if name_co2 != "CO2 buildup":
		return _fail("display_name('co2') was '%s', expected 'CO2 buildup'" % name_co2)

	# hard: trigger("o2") makes time_left 25 or less
	mgr.set("mode", "hard")
	mgr.call("start_run")
	mgr.call("trigger", "o2")
	var tl_hard: float = float(mgr.get("time_left"))
	if tl_hard > 25.0 or tl_hard <= 0.0:
		return _fail("hard mode time_left was %f, expected <= 25 and > 0" % tl_hard)

	# frozen: time_left unchanged after 0.3 s
	mgr.set("countdown_frozen", true)
	var before_freeze: float = float(mgr.get("time_left"))
	await create_timer(0.3).timeout
	var after_freeze: float = float(mgr.get("time_left"))
	if not is_equal_approx(before_freeze, after_freeze):
		return _fail("frozen time_left changed from %f to %f after 0.3s" % [before_freeze, after_freeze])

	# practice: kill("o2", "mistake") keeps running and active_id == "o2", and emits practice_mistake
	mgr.set("countdown_frozen", false)
	mgr.set("mode", "practice")
	# Lambdas capture locals by value, so record the signal into a shared Dictionary.
	var got := {}
	mgr.connect("practice_mistake", func(cause: String, detail: String) -> void:
		got["cause"] = cause
		got["detail"] = detail
	)
	mgr.call("kill", "o2", "mistake", "operator error")
	if not bool(mgr.get("running")):
		return _fail("practice mistake stopped running")
	if String(mgr.get("active_id")) != "o2":
		return _fail("practice mistake cleared active_id (got '%s')" % mgr.get("active_id"))
	if got.is_empty():
		return _fail("practice_mistake signal did not fire")
	if got["cause"] != "o2" or got["detail"] != "operator error":
		return _fail("practice_mistake payload incorrect: %s" % [got])

	print("PASS")
	mgr.free()
	quit(0)
