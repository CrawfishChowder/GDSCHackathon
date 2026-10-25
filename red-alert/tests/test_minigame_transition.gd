extends SceneTree

var _got := {}


func _fail(reason: String) -> void:
	print("FAIL: " + reason)
	quit(1)


func _initialize() -> void:
	await process_frame

	if root.get_node_or_null("SaveData") == null:
		var sd_script = load("res://scripts/systems/save_data.gd")
		if sd_script != null:
			var sd: Node = sd_script.new()
			sd.name = "SaveData"
			root.add_child(sd)
	if root.get_node_or_null("MalfunctionManager") == null:
		var mm_script = load("res://scripts/systems/malfunction_manager.gd")
		if mm_script != null:
			var mm: Node = mm_script.new()
			mm.name = "MalfunctionManager"
			root.add_child(mm)

	# The monitor CRT shader was dropped in favor of Scott's Normal Operations
	# monitor system; this test now only covers the minigame ease-in.
	var o2_scene := load("res://scenes/minigames/o2_keypad.tscn") as PackedScene
	if o2_scene == null:
		return _fail("Failed to load o2_keypad.tscn")

	var o2: Node = o2_scene.instantiate()
	root.add_child(o2)

	await create_timer(0.3, true).timeout

	var panel: Control = o2.get_node_or_null("MinigamePanel") as Control
	if panel == null:
		return _fail("MinigamePanel not found in O2 keypad")

	var alpha: float = panel.modulate.a
	if alpha < 0.99:
		return _fail("Expected panel modulate.a >= 0.99 (1.0 within 0.01), got %f" % alpha)

	o2.queue_free()
	await process_frame

	print("PASS")
	quit(0)
