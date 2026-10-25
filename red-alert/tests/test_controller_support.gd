extends SceneTree

class Target:
	extends Node
	var count: int = 0
	func interact(_by: Node) -> void:
		count += 1


func _initialize() -> void:
	await process_frame
	var cross := InputEventJoypadButton.new()
	cross.button_index = JOY_BUTTON_A
	cross.pressed = true
	var square := InputEventJoypadButton.new()
	square.button_index = JOY_BUTTON_X
	square.pressed = true
	var options := InputEventJoypadButton.new()
	options.button_index = JOY_BUTTON_START
	options.pressed = true
	var r2 := InputEventJoypadMotion.new()
	r2.axis = JOY_AXIS_TRIGGER_RIGHT
	r2.axis_value = 1.0
	var left := InputEventJoypadMotion.new()
	left.axis = JOY_AXIS_LEFT_X
	left.axis_value = -1.0
	var dpad := InputEventJoypadButton.new()
	dpad.button_index = JOY_BUTTON_DPAD_DOWN
	dpad.pressed = true
	if not cross.is_action_pressed("interact") or not cross.is_action_pressed("ui_accept"):
		return _fail("Cross must interact and select")
	if not r2.is_action_pressed("interact") or not square.is_action_pressed("jump"):
		return _fail("R2 or Square action missing")
	if not options.is_action_pressed("controller_pause"):
		return _fail("Options pause action missing")
	if not left.is_action_pressed("move_left") or not dpad.is_action_pressed("move_back") or not dpad.is_action_pressed("ui_down"):
		return _fail("Stick or D-pad navigation missing")

	var interactor := load("res://scripts/player/interactor.gd").new() as RayCast3D
	var target := Target.new()
	root.add_child(interactor)
	root.add_child(target)
	interactor.set("_current_target", target)
	interactor._unhandled_input(cross)
	interactor._unhandled_input(r2)
	if target.count != 1:
		return _fail("Cross and R2 triggered %d interactions" % target.count)
	interactor.queue_free()
	target.queue_free()

	var title := (load("res://scenes/ui/title_screen.tscn") as PackedScene).instantiate()
	root.add_child(title)
	await process_frame
	var focused := root.gui_get_focus_owner() as Button
	if focused == null or focused.text != "Start shift":
		return _fail("Title did not focus Start shift")
	title.queue_free()
	await process_frame

	var dust := (load("res://scenes/minigames/dust_storm_power.tscn") as PackedScene).instantiate()
	root.add_child(dust)
	await process_frame
	if not root.gui_get_focus_owner() is HSlider:
		return _fail("Dust storm did not focus its first slider")
	dust.queue_free()
	print("PASS")
	quit(0)


func _fail(message: String) -> void:
	print("FAIL: " + message)
	quit(1)
