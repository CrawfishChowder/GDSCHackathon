extends SceneTree


func _fail(reason: String) -> void:
	paused = false
	print("FAIL: " + reason)
	quit(1)


func _initialize() -> void:
	await process_frame

	# -------------------------------------------------------------
	# Test 1: DO NOT PRESS button freed mid-timer
	# Press interact(null), free parent room immediately, wait 2.5 s.
	# Must not error, crash, or kill the active run.
	# -------------------------------------------------------------
	var mm: Node = root.get_node_or_null("MalfunctionManager")
	if mm != null and mm.has_method("start_run"):
		mm.call("start_run")

	var button_script := load("res://scripts/stage1/do_not_press_button.gd") as GDScript
	if button_script == null:
		return _fail("Failed to load do_not_press_button.gd")

	var dummy_room := Node3D.new()
	dummy_room.name = "DummyRoom"
	root.add_child(dummy_room)

	var button: Node3D = button_script.new()
	dummy_room.add_child(button)
	await process_frame

	button.interact(null)
	dummy_room.free()

	# Wait 2.5s for the button's internal 2.0s timer to expire
	await create_timer(2.5).timeout

	if mm != null and not bool(mm.get("running")):
		return _fail("Freed button triggered death after being deleted")

	# -------------------------------------------------------------
	# Test 2: Story director stops cleanly when player dies
	# In story mode, kill run at 25 s and check director stops triggering.
	# -------------------------------------------------------------
	var story_script := load("res://scripts/stage1/story_director.gd") as GDScript
	if story_script == null:
		return _fail("Failed to load story_director.gd")

	var story_director: Node = story_script.new()
	root.add_child(story_director)

	if mm != null:
		mm.set("mode", "story")
		mm.call("start_run")
		# Advance time past beat 0 (20s)
		mm.set("survived_seconds", 21.0)
		story_director._process(1.0)
		var beat0: int = int(story_director.next_beat_index())
		if beat0 != 1:
			story_director.free()
			return _fail("Expected story beat 0 to have fired (beat index 1), got %d" % beat0)

		# Clear active malfunction and advance to 25s
		mm.call("fix", "o2")
		mm.set("survived_seconds", 25.0)

		# Kill the run at 25s
		mm.call("kill", "reactor", "mistake", "Story test kill")

		# Now advance time past beat 1 (70s) to 75s and process
		mm.set("survived_seconds", 75.0)
		story_director._process(1.0)

		var beat_after_death: int = int(story_director.next_beat_index())
		if beat_after_death != 1:
			story_director.free()
			return _fail("Story director triggered beat after player death; beat index is %d" % beat_after_death)

		if not bool(story_director.is_stopped()):
			story_director.free()
			return _fail("Story director is_stopped is false after player_died")

	story_director.free()

	# -------------------------------------------------------------
	# Test 3: Demo helper ignores keys while tree is paused
	# -------------------------------------------------------------
	var demo_script := load("res://scripts/stage1/demo_helper.gd") as GDScript
	if demo_script == null:
		return _fail("Failed to load demo_helper.gd")

	var demo_helper: Node = demo_script.new()
	root.add_child(demo_helper)
	await process_frame

	paused = true
	var handled_paused: bool = bool(demo_helper.handle_key(KEY_F4))
	if handled_paused:
		paused = false
		demo_helper.free()
		return _fail("DemoHelper handled key while tree was paused")

	paused = false
	var handled_unpaused: bool = bool(demo_helper.handle_key(KEY_F4))
	if not handled_unpaused:
		demo_helper.free()
		return _fail("DemoHelper did not handle key while tree was unpaused")

	demo_helper.free()

	# -------------------------------------------------------------
	# Test 4: Tutorial director survives player death cleanly
	# -------------------------------------------------------------
	var tutorial_script := load("res://scripts/stage1/tutorial_director.gd") as GDScript
	if tutorial_script == null:
		return _fail("Failed to load tutorial_director.gd")

	var tutorial: Node = tutorial_script.new()
	root.add_child(tutorial)
	await process_frame

	if mm != null and mm.has_signal("player_died"):
		mm.player_died.emit("o2", "Depletion")
		var step: int = int(tutorial.current_step())
		if step != 0:
			tutorial.free()
			return _fail("Tutorial director step not reset to 0 on player death")

	tutorial.free()

	paused = false
	print("PASS")
	quit(0)
