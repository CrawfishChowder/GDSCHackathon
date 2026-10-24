extends SceneTree

var _completed_fired: bool = false


func _initialize() -> void:
	var scene_res := load("res://scenes/minigames/reactor_sequence.tscn") as PackedScene
	if scene_res == null:
		print("FAIL: Failed to load reactor sequence scene")
		quit(1)
		return

	var minigame: Variant = scene_res.instantiate()
	if minigame == null:
		print("FAIL: Failed to instantiate reactor sequence scene")
		quit(1)
		return

	root.add_child(minigame)

	var elapsed: float = 0.0
	while not minigame.accepting_input and elapsed < 5.0:
		await create_timer(0.1, true, false, true).timeout
		elapsed += 0.1

	if not minigame.accepting_input:
		print("FAIL: Timed out waiting for accepting_input")
		quit(1)
		return

	minigame.completed.connect(func() -> void:
		_completed_fired = true
	)

	var seq: Array = minigame.sequence
	if seq.size() != 4:
		print("FAIL: Sequence size is not 4")
		quit(1)
		return

	for idx in seq:
		minigame.press(idx)

	if not _completed_fired:
		await create_timer(0.05, true, false, true).timeout

	if not _completed_fired:
		print("FAIL: completed signal was not emitted")
		quit(1)
		return

	print("PASS")
	quit(0)
