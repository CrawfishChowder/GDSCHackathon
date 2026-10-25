extends SceneTree


func _fail(reason: String) -> void:
	print("FAIL: " + reason)
	quit(1)


func _initialize() -> void:
	await process_frame

	var sd: Node = root.get_node_or_null("SaveData")
	if sd == null and ResourceLoader.exists("res://scripts/systems/save_data.gd"):
		var sd_script := load("res://scripts/systems/save_data.gd")
		if sd_script != null:
			sd = sd_script.new()
			sd.name = "SaveData"
			root.add_child(sd)
			await process_frame

	var st: Node = root.get_node_or_null("Settings")
	if st == null and ResourceLoader.exists("res://scripts/systems/settings.gd"):
		var st_script := load("res://scripts/systems/settings.gd")
		if st_script != null:
			st = st_script.new()
			st.name = "Settings"
			root.add_child(st)
			await process_frame

	var mm: Node = root.get_node_or_null("MalfunctionManager")
	if mm == null and ResourceLoader.exists("res://scripts/systems/malfunction_manager.gd"):
		var mm_script := load("res://scripts/systems/malfunction_manager.gd")
		if mm_script == null:
			return _fail("Failed to load malfunction_manager.gd")
		mm = mm_script.new()
		mm.name = "MalfunctionManager"
		root.add_child(mm)
		await process_frame

	if not root.has_node("MissionLog") and ResourceLoader.exists("res://scripts/systems/mission_log.gd"):
		var ml_script := load("res://scripts/systems/mission_log.gd")
		if ml_script != null:
			var ml: Node = ml_script.new()
			ml.name = "MissionLog"
			root.add_child(ml)
			await process_frame

	if sd == null:
		return _fail("SaveData not found")

	sd.call("set_value", "seen_co2", false)

	var hud_scene := load("res://scenes/ui/hud.tscn")
	if hud_scene == null:
		return _fail("Failed to load hud.tscn")
	var hud: Node = hud_scene.instantiate()
	root.add_child(hud)
	await process_frame

	var brief: Node = hud.get_node_or_null("CrisisBrief")
	if brief == null:
		brief = hud.find_child("CrisisBrief", true, false)
	if brief == null:
		return _fail("CrisisBrief not found in hud")

	if brief.call("is_showing"):
		return _fail("CrisisBrief should not be showing initially")

	mm.call("start_run")
	mm.call("trigger", "co2")
	await process_frame
	await process_frame

	if not brief.call("is_showing"):
		return _fail("CrisisBrief should be showing after first co2 trigger")

	var text: String = String(brief.call("current_text"))
	if not text.contains("checklist order"):
		return _fail("CrisisBrief text was '%s', expected to contain 'checklist order'" % text)
	if not text.contains("Left console"):
		return _fail("CO2 crisis brief points to the wrong console")

	var time_left: float = float(mm.get("time_left"))
	if time_left <= 45.0:
		return _fail("time_left was %f, expected > 45.0" % time_left)

	mm.call("fix", "co2")
	await process_frame
	await process_frame

	mm.call("trigger", "co2")
	await process_frame
	await process_frame

	var time_left_second: float = float(mm.get("time_left"))
	if time_left_second > 45.0:
		return _fail("Grace should not be added on second trigger: time_left = %f" % time_left_second)

	if brief.call("is_showing"):
		return _fail("CrisisBrief should not show on second trigger of co2")
	brief.call("_show_brief", "o2", "O2 depletion")
	if not String(brief.call("current_text")).contains("Right console"):
		return _fail("O2 crisis brief points to the wrong console")

	paused = false
	print("PASS")
	quit(0)
