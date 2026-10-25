extends SceneTree


func _initialize() -> void:
	await process_frame

	var save_data := root.get_node_or_null("SaveData")
	if save_data == null:
		print("FAIL: SaveData autoload not found")
		paused = false
		quit(1)
		return

	var settings := root.get_node_or_null("Settings")
	if settings == null:
		print("FAIL: Settings autoload not found")
		paused = false
		quit(1)
		return

	var mm := root.get_node_or_null("MalfunctionManager")
	if mm == null:
		print("FAIL: MalfunctionManager autoload not found")
		paused = false
		quit(1)
		return

	save_data.call("set_value", "controls_seen", false)

	var hud_scene := load("res://scenes/ui/hud.tscn") as PackedScene
	if hud_scene == null:
		print("FAIL: Failed to load res://scenes/ui/hud.tscn")
		paused = false
		quit(1)
		return

	var hud := hud_scene.instantiate()
	if hud == null:
		print("FAIL: Failed to instantiate hud")
		paused = false
		quit(1)
		return

	root.add_child(hud)
	await process_frame

	mm.call("start_run")
	await process_frame
	await process_frame

	var cp: Control = null
	if "controls_panel" in hud and hud.controls_panel != null:
		cp = hud.controls_panel
	else:
		cp = hud.get_node_or_null("ControlsPanel")
	if cp == null:
		for child in hud.get_children():
			if child.has_method("is_open"):
				cp = child
				break

	if cp == null:
		print("FAIL: ControlsPanel not found on HUD")
		mm.call("stop_run")
		hud.queue_free()
		paused = false
		quit(1)
		return

	if not bool(cp.call("is_open")):
		print("FAIL: ControlsPanel is not open after start_run with controls_seen=false")
		mm.call("stop_run")
		hud.queue_free()
		paused = false
		quit(1)
		return

	var text: String = str(cp.call("text_content"))
	if not text.contains("HOLD B TO BREATHE"):
		print("FAIL: ControlsPanel text_content does not contain 'HOLD B TO BREATHE'")
		mm.call("stop_run")
		hud.queue_free()
		paused = false
		quit(1)
		return

	cp.call("toggle")
	if bool(cp.call("is_open")):
		print("FAIL: ControlsPanel is not closed after toggle()")
		mm.call("stop_run")
		hud.queue_free()
		paused = false
		quit(1)
		return

	settings.call("set_setting", "hide_hud", true)
	await process_frame

	var hint_lbl: Control = null
	if "controls_hint_label" in hud and hud.controls_hint_label != null:
		hint_lbl = hud.controls_hint_label
	else:
		hint_lbl = hud.get_node_or_null("ControlsHintLabel")
	if hint_lbl == null:
		for child in hud.find_children("*", "Label", true, false):
			if child is Label and child.text.contains("controls"):
				hint_lbl = child
				break

	if hint_lbl == null:
		print("FAIL: Controls hint label not found on HUD")
		settings.call("set_setting", "hide_hud", false)
		mm.call("stop_run")
		hud.queue_free()
		paused = false
		quit(1)
		return

	if hint_lbl.visible:
		print("FAIL: Controls hint label should be hidden when hide_hud is true")
		settings.call("set_setting", "hide_hud", false)
		mm.call("stop_run")
		hud.queue_free()
		paused = false
		quit(1)
		return

	settings.call("set_setting", "hide_hud", false)
	await process_frame

	if not hint_lbl.visible:
		print("FAIL: Controls hint label should be visible when hide_hud is false")
		mm.call("stop_run")
		hud.queue_free()
		paused = false
		quit(1)
		return

	mm.call("stop_run")
	hud.queue_free()
	await process_frame

	paused = false
	print("PASS")
	quit(0)
