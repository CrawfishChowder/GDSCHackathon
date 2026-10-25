extends SceneTree

# The pause menu must freeze the countdown; an open minigame must not.


func _initialize() -> void:
	await process_frame
	var mm: Node = root.get_node("MalfunctionManager")
	var host: Node = root.get_node("MinigameHost")
	mm.start_run()
	mm.trigger("o2")

	paused = true
	var before: float = mm.time_left
	await create_timer(0.4).timeout
	if not is_equal_approx(before, mm.time_left):
		print("FAIL: countdown ran while paused without a minigame")
		paused = false
		quit(1)
		return

	host.open(load("res://scenes/minigames/o2_keypad.tscn"), "o2")
	before = mm.time_left
	await create_timer(0.4).timeout
	host.close()
	paused = false
	if mm.time_left >= before:
		print("FAIL: countdown froze while a minigame was open")
		quit(1)
		return
	print("PASS")
	quit(0)
