extends SceneTree

var _completed_fired: bool = false
var _fail_test_completed_fired: bool = false
var _failed_fired: bool = false
var _fail_reason: String = ""


func _initialize() -> void:
	var keypad_scene := load("res://scenes/minigames/o2_keypad.tscn") as PackedScene
	if keypad_scene == null:
		print("FAIL: Failed to load o2_keypad scene")
		quit(1)
		return

	# --- Success Path ---
	var keypad: Node = keypad_scene.instantiate()
	if keypad == null:
		print("FAIL: Failed to instantiate o2_keypad scene")
		quit(1)
		return

	root.add_child(keypad)
	await process_frame

	keypad.connect("completed", func() -> void: _completed_fired = true)

	var code: String = keypad.get("code")
	if code.length() != 5:
		print("FAIL: Keypad code is not 5 digits: %s" % code)
		quit(1)
		return

	# Test CLR key functionality
	keypad.call("press_key", "1")
	keypad.call("press_key", "2")
	keypad.call("press_key", "CLR")
	if not String(keypad.get("entered")).is_empty():
		print("FAIL: CLR did not clear entered buffer")
		quit(1)
		return

	# Enter correct code
	for i in range(code.length()):
		keypad.call("press_key", code[i])

	keypad.call("press_key", "ENTER")

	if not _completed_fired:
		print("FAIL: Minigame did not complete on correct code")
		quit(1)
		return

	keypad.queue_free()
	await process_frame

	# --- Failure Path ---
	var keypad_fail: Node = keypad_scene.instantiate()
	if keypad_fail == null:
		print("FAIL: Failed to instantiate second o2_keypad scene")
		quit(1)
		return

	root.add_child(keypad_fail)
	await process_frame

	keypad_fail.connect("completed", func() -> void: _fail_test_completed_fired = true)
	keypad_fail.connect("failed", func(reason: String) -> void:
		_failed_fired = true
		_fail_reason = reason
	)

	var target_code: String = keypad_fail.get("code")
	var wrong_code := "00000" if target_code != "00000" else "11111"
	for i in range(wrong_code.length()):
		keypad_fail.call("press_key", wrong_code[i])

	keypad_fail.call("press_key", "ENTER")

	if not _failed_fired:
		await create_timer(0.05).timeout

	if not _failed_fired:
		print("FAIL: failed signal did not fire on wrong code ENTER")
		quit(1)
		return

	if _fail_test_completed_fired:
		print("FAIL: completed signal fired on wrong code ENTER")
		quit(1)
		return

	if _fail_reason.is_empty():
		print("FAIL: failed reason was empty")
		quit(1)
		return

	print("PASS")
	quit(0)
