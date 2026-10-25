extends SceneTree


func _fail(reason: String) -> void:
	print("FAIL: " + reason)
	quit(1)


func _initialize() -> void:
	await process_frame

	var sd: Node = root.get_node_or_null("SaveData")
	if sd == null:
		var sd_script := load("res://scripts/systems/save_data.gd") as GDScript
		if sd_script == null:
			return _fail("Failed to load save_data.gd")
		sd = sd_script.new()
		sd.name = "SaveData"
		root.add_child(sd)
		await process_frame

	var mm: Node = root.get_node_or_null("MalfunctionManager")
	if mm == null:
		var mm_script := load("res://scripts/systems/malfunction_manager.gd") as GDScript
		if mm_script == null:
			return _fail("Failed to load malfunction_manager.gd")
		mm = mm_script.new()
		mm.name = "MalfunctionManager"
		root.add_child(mm)
		await process_frame

	var voice: Node = root.get_node_or_null("Voice")
	if voice == null:
		var v_script := load("res://scripts/systems/voice.gd") as GDScript
		if v_script != null:
			voice = v_script.new()
			voice.name = "Voice"
			root.add_child(voice)
			await process_frame

	var mh: Node = root.get_node_or_null("MinigameHost")
	if mh == null:
		var mh_scene := load("res://scenes/ui/minigame_host.tscn") as PackedScene
		if mh_scene != null:
			mh = mh_scene.instantiate()
			mh.name = "MinigameHost"
			root.add_child(mh)
			await process_frame

	mm.set("mode", "normal")
	if bool(mm.get("running")):
		mm.call("stop_run")

	sd.call("set_value", "tutorial_done", false)

	var room_scene := load("res://scenes/stage1/stage_1_room.tscn") as PackedScene
	if room_scene == null:
		return _fail("Failed to load stage_1_room.tscn")
	var room: Node = room_scene.instantiate()
	root.add_child(room)

	await create_timer(6.5, true).timeout

	var director := room.get_node_or_null("TutorialDirector")
	if director == null:
		return _fail("TutorialDirector node not found in room")

	if not bool(mm.call("is_active", "o2")):
		return _fail("o2 malfunction not active after 6.5 s (active_id='%s')" % mm.get("active_id"))

	if not bool(mm.get("countdown_frozen")):
		return _fail("countdown_frozen is false, expected true")

	var step: int = int(director.call("current_step"))
	if step != 1:
		return _fail("current_step was %d, expected 1" % step)
	var banner := director.get("_label") as Label
	if banner == null or not banner.text.contains("RIGHT CONSOLE"):
		return _fail("O2 tutorial banner points to the wrong console")

	var player := room.get_node_or_null("FirstPersonPlayer") as Node3D
	if player == null:
		return _fail("FirstPersonPlayer not found in room")

	var station := room.get_node_or_null("MainConsole/LeftStation/O2Station") as Node3D
	if station == null:
		return _fail("MainConsole/LeftStation/O2Station not found in room")

	player.global_position = station.global_position + Vector3(0.0, 0.0, 0.5)
	await create_timer(0.3, true).timeout

	step = int(director.call("current_step"))
	if step != 2:
		return _fail("current_step was %d after moving player near O2Station, expected 2" % step)

	mm.call("fix", "o2")
	await create_timer(0.3, true).timeout

	step = int(director.call("current_step"))
	if step != 4:
		return _fail("current_step was %d after fix('o2'), expected 4" % step)

	if bool(mm.get("countdown_frozen")):
		return _fail("countdown_frozen is true after fix('o2'), expected false")

	sd.call("set_value", "tutorial_done", false)

	print("PASS")
	quit(0)
