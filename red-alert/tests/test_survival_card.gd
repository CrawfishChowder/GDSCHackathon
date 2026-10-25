extends SceneTree


func _fail(reason: String) -> void:
	print("FAIL: " + reason)
	quit(1)


func _initialize() -> void:
	await process_frame

	if not root.has_node("SaveData") and ResourceLoader.exists("res://scripts/systems/save_data.gd"):
		var sd_script := load("res://scripts/systems/save_data.gd")
		if sd_script != null:
			var sd: Node = sd_script.new()
			sd.name = "SaveData"
			root.add_child(sd)
			await process_frame

	if not root.has_node("Settings") and ResourceLoader.exists("res://scripts/systems/settings.gd"):
		var st_script := load("res://scripts/systems/settings.gd")
		if st_script != null:
			var st: Node = st_script.new()
			st.name = "Settings"
			root.add_child(st)
			await process_frame

	var mm: Node
	if root.has_node("MalfunctionManager"):
		mm = root.get_node("MalfunctionManager")
	else:
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

	var hud_scene := load("res://scenes/ui/hud.tscn")
	if hud_scene == null:
		return _fail("Failed to load hud.tscn")
	var hud: Node = hud_scene.instantiate()
	root.add_child(hud)
	await process_frame

	var card: Node = hud.get_node_or_null("SurvivalCard")
	if card == null:
		return _fail("SurvivalCard child not found in hud.tscn")

	if card.call("is_showing"):
		return _fail("SurvivalCard should be hidden initially")

	# Test survival card for "power"
	mm.call("start_run")
	mm.call("trigger", "power")
	mm.call("fix", "power")

	await create_timer(0.5).timeout

	if not card.call("is_showing"):
		return _fail("SurvivalCard.is_showing() was false after fix('power')")

	var title: String = String(card.call("current_title"))
	if not title.contains("Apollo 12"):
		return _fail("SurvivalCard.current_title() was '%s', expected to contain 'Apollo 12'" % title)

	# Test practice mistake card
	mm.set("mode", "practice")
	mm.call("kill", "reactor", "mistake", "wrong rod sequence")

	await create_timer(0.5).timeout

	if not card.call("is_showing"):
		return _fail("SurvivalCard.is_showing() was false after practice mistake")

	var practice_title: String = String(card.call("current_title"))
	if not practice_title.contains("SL-1"):
		return _fail("SurvivalCard.current_title() was '%s', expected to contain 'SL-1'" % practice_title)

	print("PASS")
	quit(0)
