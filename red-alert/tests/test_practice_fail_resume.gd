extends SceneTree

# Regression (Scott's playtest): after a minigame mistake in Practice mode, the
# game must unpause and mouse look must be handed back to the player.


func _initialize() -> void:
	await process_frame
	var mm: Node = root.get_node("MalfunctionManager")
	var host: Node = root.get_node("MinigameHost")
	root.get_node("SaveData").set_value("tutorial_done", true)
	mm.mode = "practice"
	change_scene_to_file("res://scenes/stage1/stage_1_room.tscn")
	for i in 3:
		await process_frame

	mm.trigger("o2")
	host.open(load("res://scenes/minigames/o2_keypad.tscn"), "o2")
	await process_frame
	host.current.fail("test mistake")
	for i in 3:
		await process_frame

	var ok: bool = not paused and not host.is_open() and mm.running and mm.is_active("o2")
	var player: Node = current_scene.get_node("FirstPersonPlayer")
	ok = ok and bool(player.get("_mouse_look_active"))
	mm.mode = "normal"
	paused = false
	if not ok:
		print("FAIL: paused=%s open=%s running=%s look=%s" % [paused, host.is_open(), mm.running, player.get("_mouse_look_active")])
		quit(1)
		return
	print("PASS")
	quit(0)
