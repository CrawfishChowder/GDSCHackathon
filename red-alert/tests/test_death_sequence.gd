extends SceneTree


func _fail(reason: String) -> void:
	paused = false
	print("FAIL: " + reason)
	quit(1)


func _initialize() -> void:
	await process_frame

	var ml: Node = root.get_node_or_null("MissionLog")
	if ml == null:
		return _fail("MissionLog autoload not found")

	var hud_scene := load("res://scenes/ui/hud.tscn") as PackedScene
	if hud_scene == null:
		return _fail("Failed to load hud.tscn")

	var hud: Node = hud_scene.instantiate()
	if hud == null:
		return _fail("Failed to instantiate hud.tscn")

	root.add_child(hud)
	await process_frame
	await process_frame

	var go: Node = hud.get_node_or_null("GameOver")
	if go == null:
		return _fail("GameOver not found under HUD")

	if not go.has_method("sequence_running"):
		return _fail("GameOver missing sequence_running method")

	if not go.has_method("is_showing"):
		return _fail("GameOver missing is_showing method")

	ml.call("record_death", "o2", "mistake", "t")

	await create_timer(0.2).timeout

	if not bool(go.call("sequence_running")):
		return _fail("expected GameOver.sequence_running() == true at 0.2s")

	await create_timer(3.0).timeout

	if bool(go.call("sequence_running")):
		return _fail("expected GameOver.sequence_running() == false after 3.0s")

	if not bool(go.call("is_showing")):
		return _fail("expected GameOver.is_showing() == true after 3.0s")

	# Verify R / skip skips the sequence immediately
	ml.call("record_death", "co2", "mistake", "t2")
	await create_timer(0.1).timeout

	if not bool(go.call("sequence_running")):
		return _fail("expected GameOver.sequence_running() == true on second death")

	var key_ev := InputEventKey.new()
	key_ev.pressed = true
	key_ev.keycode = KEY_R
	key_ev.physical_keycode = KEY_R
	go.call("_unhandled_input", key_ev)

	if bool(go.call("sequence_running")):
		return _fail("expected GameOver.sequence_running() == false after R key during sequence")

	if not bool(go.call("is_showing")):
		return _fail("expected GameOver.is_showing() == true after R key during sequence")

	paused = false
	hud.queue_free()
	print("PASS")
	quit(0)
