extends SceneTree

var _completed_fired: bool = false
var _fail_test_completed_fired: bool = false
var _failed_fired: bool = false
var _fail_reason: String = ""


func _initialize() -> void:
	var scene_res := load("res://scenes/minigames/reactor_sequence.tscn") as PackedScene
	if scene_res == null:
		print("FAIL: Failed to load reactor sequence scene")
		quit(1)
		return

	# --- Success Path ---
	var minigame: Node = scene_res.instantiate()
	if minigame == null:
		print("FAIL: Failed to instantiate reactor sequence scene")
		quit(1)
		return

	root.add_child(minigame)
	await process_frame

	var elapsed: float = 0.0
	while not minigame.get("accepting_input") and elapsed < 5.0:
		await create_timer(0.1, true, false, true).timeout
		elapsed += 0.1

	if not minigame.get("accepting_input"):
		print("FAIL: Timed out waiting for accepting_input")
		quit(1)
		return

	minigame.connect("completed", func() -> void:
		_completed_fired = true
	)

	var seq: Array = minigame.get("sequence")
	if seq.size() != 4:
		print("FAIL: Sequence size is not 4")
		quit(1)
		return

	for idx in seq:
		minigame.call("press", idx)

	if not _completed_fired:
		await create_timer(0.05, true, false, true).timeout

	if not _completed_fired:
		print("FAIL: completed signal was not emitted")
		quit(1)
		return

	minigame.queue_free()
	await process_frame

	# --- Failure Path ---
	var minigame_fail: Node = scene_res.instantiate()
	if minigame_fail == null:
		print("FAIL: Failed to instantiate second reactor sequence scene")
		quit(1)
		return

	root.add_child(minigame_fail)
	await process_frame

	elapsed = 0.0
	while not minigame_fail.get("accepting_input") and elapsed < 5.0:
		await create_timer(0.1, true, false, true).timeout
		elapsed += 0.1

	if not minigame_fail.get("accepting_input"):
		print("FAIL: Timed out waiting for accepting_input on second minigame")
		quit(1)
		return

	minigame_fail.connect("completed", func() -> void:
		_fail_test_completed_fired = true
	)
	minigame_fail.connect("failed", func(reason: String) -> void:
		_failed_fired = true
		_fail_reason = reason
	)

	var seq_fail: Array = minigame_fail.get("sequence")
	var wrong_idx: int = (int(seq_fail[0]) + 1) % 4
	minigame_fail.call("press", wrong_idx)

	if not _failed_fired:
		await create_timer(0.05, true, false, true).timeout

	if not _failed_fired:
		print("FAIL: failed signal was not emitted on wrong press")
		quit(1)
		return

	if _fail_test_completed_fired:
		print("FAIL: completed signal was emitted on wrong press")
		quit(1)
		return

	if _fail_reason.is_empty():
		print("FAIL: failed reason was empty")
		quit(1)
		return

	print("PASS")
	quit(0)
