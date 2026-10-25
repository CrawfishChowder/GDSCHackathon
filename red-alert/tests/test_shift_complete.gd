extends SceneTree


func _fail(reason: String) -> void:
	paused = false
	print("FAIL: " + reason)
	quit(1)


func _initialize() -> void:
	var mm: Node = root.get_node_or_null("MalfunctionManager")
	if mm == null:
		mm = load("res://scripts/systems/malfunction_manager.gd").new()
		mm.name = "MalfunctionManager"
		root.add_child(mm)
		await process_frame

	var hud_scene := load("res://scenes/ui/hud.tscn") as PackedScene
	if hud_scene == null:
		return _fail("Failed to load hud.tscn")

	var hud: Node = hud_scene.instantiate()
	if hud == null:
		return _fail("Failed to instantiate hud.tscn")

	root.add_child(hud)
	await process_frame

	var shift_complete: Node = hud.get_node_or_null("ShiftComplete")
	if shift_complete == null:
		shift_complete = hud.find_child("ShiftComplete", true, false)
	if shift_complete == null:
		return _fail("ShiftComplete node not found in HUD")

	if shift_complete.is_showing():
		return _fail("ShiftComplete is_showing() is true before shift reached SHIFT_LENGTH")

	mm.start_run()
	mm.survived_seconds = mm.SHIFT_LENGTH
	await create_timer(0.2, true, false, true).timeout

	if not shift_complete.is_showing():
		return _fail("ShiftComplete is_showing() is false after shift reached SHIFT_LENGTH")

	paused = false
	print("PASS")
	quit(0)
