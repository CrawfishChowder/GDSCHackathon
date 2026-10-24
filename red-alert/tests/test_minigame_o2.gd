extends SceneTree

var _completed_fired: bool = false


func _initialize() -> void:
	var keypad_scene := load("res://scenes/minigames/o2_keypad.tscn") as PackedScene
	if keypad_scene == null:
		print("FAIL: Failed to load o2_keypad scene")
		quit(1)
		return

	var keypad := keypad_scene.instantiate() as O2Keypad
	if keypad == null:
		print("FAIL: Failed to instantiate o2_keypad scene")
		quit(1)
		return

	root.add_child(keypad)

	keypad.completed.connect(func() -> void: _completed_fired = true)

	if keypad.code.length() != 5:
		print("FAIL: Keypad code is not 5 digits: %s" % keypad.code)
		quit(1)
		return

	# Test CLR key functionality
	keypad.press_key("1")
	keypad.press_key("2")
	keypad.press_key("CLR")
	if not keypad.entered.is_empty():
		print("FAIL: CLR did not clear entered buffer")
		quit(1)
		return

	# Build a wrong code that is guaranteed to differ from keypad.code
	var wrong_code := "00000" if keypad.code != "00000" else "11111"
	for i in range(wrong_code.length()):
		keypad.press_key(wrong_code[i])

	keypad.press_key("ENTER")

	if _completed_fired:
		print("FAIL: Minigame completed on wrong code")
		quit(1)
		return

	if not keypad.entered.is_empty():
		print("FAIL: Entered buffer was not cleared on wrong code ENTER")
		quit(1)
		return

	# Enter correct code
	for i in range(keypad.code.length()):
		keypad.press_key(keypad.code[i])

	keypad.press_key("ENTER")

	if not _completed_fired:
		print("FAIL: Minigame did not complete on correct code")
		quit(1)
		return

	print("PASS")
	quit(0)
