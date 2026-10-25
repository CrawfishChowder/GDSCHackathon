extends SceneTree


func _fail(reason: String) -> void:
	print("FAIL: " + reason)
	quit(1)


func _find_buttons(node: Node, buttons: Array[Button]) -> void:
	if node is Button:
		buttons.append(node as Button)
	for child in node.get_children():
		_find_buttons(child, buttons)


func _initialize() -> void:
	await process_frame

	# 1. Instance title_screen.tscn and assert buttons contain "Start shift", "Practice", "Hard"
	var title_scene := load("res://scenes/ui/title_screen.tscn") as PackedScene
	if title_scene == null:
		return _fail("Failed to load res://scenes/ui/title_screen.tscn")
	var title_inst := title_scene.instantiate()
	root.add_child(title_inst)
	await process_frame

	var buttons: Array[Button] = []
	_find_buttons(title_inst, buttons)

	var has_start := false
	var has_practice := false
	var has_hard := false
	for btn in buttons:
		var txt := btn.text
		if txt.contains("Start shift"):
			has_start = true
		if txt.contains("Practice"):
			has_practice = true
		if txt.contains("Hard"):
			has_hard = true

	if not has_start:
		return _fail("title_screen missing 'Start shift' button")
	if not has_practice:
		return _fail("title_screen missing 'Practice' button")
	if not has_hard:
		return _fail("title_screen missing 'Hard' button")

	title_inst.free()
	await process_frame

	# 2. Settings: set mouse_sensitivity to 1.5, assert get_setting returns 1.5, then reset to 1.0
	var settings := root.get_node_or_null("Settings")
	if settings == null:
		return _fail("Autoload Settings not found under root")

	settings.call("set_setting", "mouse_sensitivity", 1.5)
	var got_sens: Variant = settings.call("get_setting", "mouse_sensitivity")
	if not is_equal_approx(float(got_sens), 1.5):
		return _fail("Settings.get_setting('mouse_sensitivity') expected 1.5, got %s" % str(got_sens))

	settings.call("set_setting", "mouse_sensitivity", 1.0)
	var reset_sens: Variant = settings.call("get_setting", "mouse_sensitivity")
	if not is_equal_approx(float(reset_sens), 1.0):
		return _fail("Settings.get_setting('mouse_sensitivity') reset expected 1.0, got %s" % str(reset_sens))

	# 3. Instance hud.tscn and assert a PauseMenu child exists with visible == false
	var hud_scene := load("res://scenes/ui/hud.tscn") as PackedScene
	if hud_scene == null:
		return _fail("Failed to load res://scenes/ui/hud.tscn")
	var hud_inst := hud_scene.instantiate()
	root.add_child(hud_inst)
	await process_frame

	var pause_menu := hud_inst.get_node_or_null("PauseMenu")
	if pause_menu == null:
		return _fail("hud.tscn missing PauseMenu child")
	if pause_menu.get("visible") != false:
		return _fail("hud.tscn PauseMenu visible expected false, got %s" % str(pause_menu.get("visible")))

	hud_inst.free()
	await process_frame

	print("PASS")
	quit(0)
