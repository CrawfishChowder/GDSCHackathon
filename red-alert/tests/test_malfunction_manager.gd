extends SceneTree

var _started_id: String = ""
var _started_name: String = ""
var _started_limit: float = 0.0
var _fixed_id: String = ""
var _died_cause: String = ""
var _died_name: String = ""


func _initialize() -> void:
	var script := load("res://scripts/systems/malfunction_manager.gd") as GDScript
	if script == null:
		print("FAIL: Failed to load malfunction_manager.gd")
		quit(1)
		return

	var m: Node = script.new()
	if m == null:
		print("FAIL: Failed to instantiate malfunction manager")
		quit(1)
		return

	root.add_child(m)

	m.malfunction_started.connect(func(id: String, dname: String, limit: float) -> void:
		_started_id = id
		_started_name = dname
		_started_limit = limit
	)
	m.malfunction_fixed.connect(func(id: String) -> void:
		_fixed_id = id
	)
	m.player_died.connect(func(cause_id: String, dname: String) -> void:
		_died_cause = cause_id
		_died_name = dname
	)

	m.start_run()
	if not m.running:
		print("FAIL: start_run did not set running to true")
		quit(1)
		return

	# Assert 1: trigger("o2") emits malfunction_started and sets is_active("o2").
	m.trigger("o2")
	if _started_id != "o2":
		print("FAIL: trigger o2 did not emit malfunction_started with o2")
		quit(1)
		return
	if not m.is_active("o2"):
		print("FAIL: is_active o2 is false after trigger")
		quit(1)
		return
	if m.active_id != "o2":
		print("FAIL: active_id is not o2")
		quit(1)
		return

	# Assert 2: A second trigger("reactor") is a no-op.
	_started_id = ""
	m.trigger("reactor")
	if _started_id != "":
		print("FAIL: second trigger was not a no-op (emitted malfunction_started)")
		quit(1)
		return
	if m.active_id != "o2":
		print("FAIL: active_id changed on second trigger")
		quit(1)
		return
	if not m.is_active("o2") or m.is_active("reactor"):
		print("FAIL: is_active state changed on second trigger")
		quit(1)
		return

	# Assert 3: fix("reactor") is a no-op, and fix("o2") clears the malfunction and makes fixes_count == 1.
	_fixed_id = ""
	m.fix("reactor")
	if _fixed_id != "":
		print("FAIL: fix reactor emitted malfunction_fixed")
		quit(1)
		return
	if m.fixes_count != 0:
		print("FAIL: fixes_count changed on wrong fix")
		quit(1)
		return
	if m.active_id != "o2":
		print("FAIL: active_id changed on wrong fix")
		quit(1)
		return

	m.fix("o2")
	if _fixed_id != "o2":
		print("FAIL: fix o2 did not emit malfunction_fixed with o2")
		quit(1)
		return
	if m.fixes_count != 1:
		print("FAIL: fixes_count is not 1 after fix o2")
		quit(1)
		return
	if m.active_id != "":
		print("FAIL: active_id not cleared after fix o2")
		quit(1)
		return
	if m.is_active("o2"):
		print("FAIL: is_active o2 is true after fix o2")
		quit(1)
		return

	# Assert 4: Triggering again, setting time_left = 0.05 and waiting 0.2 s emits player_died with running == false.
	_started_id = ""
	m.trigger("reactor")
	if not m.is_active("reactor"):
		print("FAIL: failed to trigger reactor on second run")
		quit(1)
		return

	m.time_left = 0.05
	await create_timer(0.2).timeout

	if _died_cause != "reactor":
		print("FAIL: player_died not emitted with reactor cause")
		quit(1)
		return
	if _died_name != "Reactor meltdown":
		print("FAIL: player_died not emitted with Reactor meltdown name")
		quit(1)
		return
	if m.running:
		print("FAIL: running is still true after player_died")
		quit(1)
		return
	if m.active_id != "":
		print("FAIL: active_id was not cleared after player_died")
		quit(1)
		return

	print("PASS")
	quit(0)
