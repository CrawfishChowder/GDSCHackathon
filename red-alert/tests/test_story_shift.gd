extends SceneTree

var got := {}


func _fail(reason: String) -> void:
	print("FAIL: " + reason)
	paused = false
	quit(1)


func _initialize() -> void:
	await process_frame

	var existing := root.get_node_or_null("MalfunctionManager")
	if existing != null:
		root.remove_child(existing)
		existing.queue_free()
		await process_frame

	var mm_script := load("res://scripts/systems/malfunction_manager.gd") as GDScript
	if mm_script == null:
		_fail("Failed to load malfunction_manager.gd")
		return

	var m: Node = mm_script.new()
	m.name = "MalfunctionManager"
	m.set("mode", "story")
	root.add_child(m)
	await process_frame

	m.malfunction_started.connect(func(id: String, _dn: String, _lim: float) -> void:
		got["started"] = id
	)

	m.call("start_run")
	if not bool(m.get("scripted")):
		_fail("Expected scripted to be true after start_run() in story mode")
		return

	m.set("_next_in", 0.0)
	await create_timer(0.2).timeout

	if String(m.get("active_id")) != "":
		_fail("Expected no active malfunction while scripted is true, got " + String(m.get("active_id")))
		return

	var sd_script := load("res://scripts/stage1/story_director.gd") as GDScript
	if sd_script == null:
		_fail("Failed to load story_director.gd")
		return

	var director: Node = sd_script.new()
	director.name = "StoryDirector"
	root.add_child(director)
	await process_frame

	if director.call("next_beat_index") != 0:
		_fail("Expected next_beat_index() == 0 before any beat, got " + str(director.call("next_beat_index")))
		return

	m.set("survived_seconds", 21.0)
	await create_timer(0.3).timeout

	if not bool(m.call("is_active", "o2")):
		_fail("Expected is_active('o2') to be true at survived_seconds = 21")
		return

	if director.call("next_beat_index") != 1:
		_fail("Expected next_beat_index() == 1 after beat 0, got " + str(director.call("next_beat_index")))
		return

	m.call("stop_run")
	paused = false
	print("PASS")
	quit(0)
