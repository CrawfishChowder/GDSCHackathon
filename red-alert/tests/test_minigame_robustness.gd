extends SceneTree

var got: Dictionary = {}


func _fail(reason: String) -> void:
	paused = false
	print("FAIL: " + reason)
	quit(1)


func _initialize() -> void:
	await process_frame

	var mm: Node = root.get_node_or_null("MalfunctionManager")
	if mm == null and ResourceLoader.exists("res://scripts/systems/malfunction_manager.gd"):
		var mm_script: GDScript = load("res://scripts/systems/malfunction_manager.gd") as GDScript
		if mm_script != null:
			mm = mm_script.new()
			mm.name = "MalfunctionManager"
			root.add_child(mm)
			await process_frame

	var host: Node = root.get_node_or_null("MinigameHost")
	if host == null:
		var host_scene: PackedScene = load("res://scenes/ui/minigame_host.tscn") as PackedScene
		if host_scene != null:
			host = host_scene.instantiate()
			host.name = "MinigameHost"
			root.add_child(host)
			await process_frame

	if host == null:
		return _fail("MinigameHost could not be found or loaded")

	# 1. Open the reactor through MinigameHost.open and close it during playback (after 0.3 s). Wait 2 s: no errors.
	var reactor_scene: PackedScene = load("res://scenes/minigames/reactor_sequence.tscn") as PackedScene
	if reactor_scene == null:
		return _fail("Failed to load reactor_sequence.tscn")

	host.call("open", reactor_scene, "reactor")
	await create_timer(0.3, true, false, true).timeout

	host.call("close")
	await create_timer(2.0, true, false, true).timeout

	var is_open: bool = bool(host.call("is_open"))
	if is_open:
		return _fail("MinigameHost should not be open after close")

	# 2. Complete the O2 keypad, then press ENTER again: completed must have fired exactly once.
	var o2_scene: PackedScene = load("res://scenes/minigames/o2_keypad.tscn") as PackedScene
	var o2: Node = null
	if o2_scene != null:
		o2 = o2_scene.instantiate()
	else:
		var o2_script: GDScript = load("res://scripts/minigames/o2_keypad.gd") as GDScript
		if o2_script != null:
			o2 = o2_script.new()
	if o2 == null:
		return _fail("Failed to instantiate O2 keypad")

	root.add_child(o2)
	await process_frame

	got["o2_completed_count"] = 0
	o2.connect("completed", func() -> void:
		got["o2_completed_count"] = int(got["o2_completed_count"]) + 1
	)

	var code: String = str(o2.get("code"))
	for i in range(code.length()):
		var digit: int = code.substr(i, 1).to_int()
		var ev := InputEventKey.new()
		ev.pressed = true
		ev.keycode = KEY_0 + digit
		o2.call("_unhandled_input", ev)

	var enter_ev := InputEventKey.new()
	enter_ev.pressed = true
	enter_ev.keycode = KEY_ENTER
	o2.call("_unhandled_input", enter_ev)

	var count_after_first: int = int(got.get("o2_completed_count", 0))
	if count_after_first != 1:
		o2.queue_free()
		return _fail("O2 completed count expected 1 after first enter, got %d" % count_after_first)

	# Press ENTER again via event and via press_key
	o2.call("_unhandled_input", enter_ev)
	o2.call("press_key", "ENTER")

	var count_after_second: int = int(got.get("o2_completed_count", 0))
	if count_after_second != 1:
		o2.queue_free()
		return _fail("O2 completed count expected 1 after second enter, got %d" % count_after_second)

	o2.queue_free()
	await process_frame

	# 3. On the CO2 adapter, press a wrong step twice: failed must have fired exactly once.
	var co2_scene: PackedScene = load("res://scenes/minigames/co2_adapter.tscn") as PackedScene
	var co2: Node = null
	if co2_scene != null:
		co2 = co2_scene.instantiate()
	else:
		var co2_script: GDScript = load("res://scripts/minigames/co2_adapter.gd") as GDScript
		if co2_script != null:
			co2 = co2_script.new()
	if co2 == null:
		return _fail("Failed to instantiate CO2 adapter")

	root.add_child(co2)
	await process_frame

	got["co2_failed_count"] = 0
	co2.connect("failed", func(_reason: String) -> void:
		got["co2_failed_count"] = int(got["co2_failed_count"]) + 1
	)

	# _current_step is 0, so step 2 is wrong.
	var wrong_step: int = 2
	co2.call("press_step", wrong_step)

	var co2_fail_count_first: int = int(got.get("co2_failed_count", 0))
	if co2_fail_count_first != 1:
		co2.queue_free()
		return _fail("CO2 failed count expected 1 after first wrong step, got %d" % co2_fail_count_first)

	# Press wrong step again
	co2.call("press_step", wrong_step)

	var co2_fail_count_second: int = int(got.get("co2_failed_count", 0))
	if co2_fail_count_second != 1:
		co2.queue_free()
		return _fail("CO2 failed count expected 1 after second wrong step, got %d" % co2_fail_count_second)

	co2.queue_free()
	await process_frame

	# Rapid repeated press on correct step must not fail or skip states
	var co2_rapid: Node = null
	if co2_scene != null:
		co2_rapid = co2_scene.instantiate()
	else:
		var co2_script_rapid: GDScript = load("res://scripts/minigames/co2_adapter.gd") as GDScript
		if co2_script_rapid != null:
			co2_rapid = co2_script_rapid.new()
	if co2_rapid != null:
		root.add_child(co2_rapid)
		await process_frame

		got["co2_rapid_failed"] = false
		co2_rapid.connect("failed", func(_reason: String) -> void:
			got["co2_rapid_failed"] = true
		)

		co2_rapid.call("press_step", 0)
		co2_rapid.call("press_step", 0)

		if bool(got.get("co2_rapid_failed", false)):
			co2_rapid.queue_free()
			return _fail("CO2 rapid repeat of completed step caused unexpected failure")

		co2_rapid.queue_free()
		await process_frame

	paused = false
	print("PASS")
	quit(0)
