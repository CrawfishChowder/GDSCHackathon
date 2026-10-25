extends SceneTree

## Regression: with controller focus on a keypad button, keyboard Enter must submit
## the code (not press the focused button).

var got := {"completed": false, "failed": false}


func _fail(reason: String) -> void:
	paused = false
	print("FAIL: " + reason)
	quit(1)


func _press(keycode: Key) -> void:
	var ev := InputEventKey.new()
	ev.keycode = keycode
	ev.physical_keycode = keycode
	ev.pressed = true
	root.push_input(ev)
	var up := ev.duplicate() as InputEventKey
	up.pressed = false
	root.push_input(up)


func _initialize() -> void:
	await process_frame
	var mg: Node = (load("res://scenes/minigames/o2_keypad.tscn") as PackedScene).instantiate()
	root.add_child(mg)
	await process_frame
	await process_frame
	mg.connect("completed", func() -> void: got["completed"] = true)
	mg.connect("failed", func(_r: String) -> void: got["failed"] = true)
	if root.gui_get_focus_owner() == null:
		return _fail("expected a focused button (controller support)")
	var code: String = String(mg.get("code"))
	for ch in code:
		_press(KEY_0 + int(ch))
		await process_frame
	_press(KEY_ENTER)
	await process_frame
	if got["failed"]:
		return _fail("Enter pressed the focused button instead of submitting")
	if not got["completed"]:
		return _fail("Enter did not submit the code")
	print("PASS")
	quit(0)
