extends SceneTree

var got := {}


func _initialize() -> void:
	await process_frame

	# 1. Test O2 Keypad keyboard input
	var o2_scene := load("res://scenes/minigames/o2_keypad.tscn") as PackedScene
	var o2: Node = o2_scene.instantiate() if o2_scene != null else load("res://scripts/minigames/o2_keypad.gd").new()
	if o2 == null:
		print("FAIL: Failed to instantiate O2 keypad")
		quit(1)
		return

	root.add_child(o2)
	await process_frame

	o2.connect("completed", func() -> void:
		got["o2_completed"] = true
	)

	var code: String = str(o2.get("code"))
	for i in range(code.length()):
		var digit := code.substr(i, 1).to_int()
		var ev := InputEventKey.new()
		ev.pressed = true
		ev.keycode = KEY_0 + digit
		o2._unhandled_input(ev)

	var enter_ev := InputEventKey.new()
	enter_ev.pressed = true
	enter_ev.keycode = KEY_ENTER
	o2._unhandled_input(enter_ev)

	if not got.get("o2_completed", false):
		print("FAIL: O2 keypad did not emit completed on key input")
		o2.queue_free()
		quit(1)
		return

	o2.queue_free()
	await process_frame

	# 2. Test Reactor Sequence keyboard input
	var reactor_scene := load("res://scenes/minigames/reactor_sequence.tscn") as PackedScene
	var reactor: Node = reactor_scene.instantiate() if reactor_scene != null else load("res://scripts/minigames/reactor_sequence.gd").new()
	if reactor == null:
		print("FAIL: Failed to instantiate reactor sequence")
		quit(1)
		return

	root.add_child(reactor)
	await process_frame

	reactor.connect("completed", func() -> void:
		got["reactor_completed"] = true
	)

	var wait_time: float = 0.0
	while not bool(reactor.get("accepting_input")) and wait_time < 6.0:
		await create_timer(0.1, true, false, true).timeout
		wait_time += 0.1

	if not bool(reactor.get("accepting_input")):
		print("FAIL: Reactor timed out waiting for accepting_input")
		reactor.queue_free()
		quit(1)
		return

	var seq: Array = reactor.get("sequence")
	for item in seq:
		var idx := int(item)
		var ev := InputEventKey.new()
		ev.pressed = true
		ev.keycode = KEY_1 + idx
		reactor._unhandled_input(ev)

	if not got.get("reactor_completed", false):
		print("FAIL: Reactor did not emit completed on key input")
		reactor.queue_free()
		quit(1)
		return

	reactor.queue_free()
	await process_frame

	paused = false
	print("PASS")
	quit(0)
