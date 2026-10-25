extends SceneTree

# Covers MalfunctionManager.kill() and shift completion.


func _fail(reason: String) -> void:
	print("FAIL: " + reason)
	quit(1)


func _initialize() -> void:
	var m: Node = load("res://scripts/systems/malfunction_manager.gd").new()
	root.add_child(m)
	await process_frame

	var died: Array = []
	m.player_died.connect(func(id: String, dname: String) -> void: died.append([id, dname]))
	var shifts: Array = []
	m.shift_completed.connect(func() -> void: shifts.append(true))

	m.start_run()
	m.trigger("power")
	m.kill("power", "mistake", "Wrong breaker.")
	if died.size() != 1 or died[0][0] != "power" or m.death_kind != "mistake":
		return _fail("kill() did not report a mistake death: %s" % [died])
	if m.running or m.active_id != "":
		return _fail("kill() left the run active")
	m.kill("power", "mistake")
	if died.size() != 1:
		return _fail("kill() fired twice")

	m.start_run()
	m.kill("do_not_press", "button")
	if died[1][1] != "Pressed the button":
		return _fail("do_not_press display name wrong: %s" % died[1][1])

	m.start_run()
	m.survived_seconds = m.SHIFT_LENGTH - 0.01
	await create_timer(0.1).timeout
	if shifts.size() != 1 or m.running:
		return _fail("shift did not complete at SHIFT_LENGTH")

	print("PASS")
	quit(0)
