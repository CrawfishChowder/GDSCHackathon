extends SceneTree

var _completed_fired: bool = false
var _fail_test_completed_fired: bool = false
var _failed_fired: bool = false
var _fail_reason: String = ""


func _initialize() -> void:
	var scene := load("res://scenes/minigames/power_switches.tscn") as PackedScene
	if scene == null:
		print("FAIL: Failed to load power switches scene")
		quit(1)
		return

	# --- Success Path ---
	var minigame: Node = scene.instantiate()
	if minigame == null:
		print("FAIL: Failed to instantiate power switches scene")
		quit(1)
		return

	root.add_child(minigame)
	await process_frame

	var target: Array = minigame.get("target")
	var switches: Array = minigame.get("switches")

	if target.size() != 6:
		print("FAIL: target size should be 6")
		quit(1)
		return

	if switches.size() != 6:
		print("FAIL: switches size should be 6")
		quit(1)
		return

	var true_count: int = 0
	for val: bool in target:
		if val:
			true_count += 1
	if true_count < 2 or true_count > 4:
		print("FAIL: target must have at least 2 true and at least 2 false")
		quit(1)
		return

	for val: bool in switches:
		if val:
			print("FAIL: switches should start all false")
			quit(1)
			return

	minigame.connect("completed", func() -> void: _completed_fired = true)

	for i in range(target.size()):
		if target[i]:
			minigame.call("toggle", i)

	await create_timer(0.5).timeout

	if not _completed_fired:
		print("FAIL: completed signal did not fire")
		quit(1)
		return

	minigame.queue_free()
	await process_frame

	# --- Failure Path ---
	var minigame_fail: Node = scene.instantiate()
	if minigame_fail == null:
		print("FAIL: Failed to instantiate second power switches scene")
		quit(1)
		return

	root.add_child(minigame_fail)
	await process_frame

	minigame_fail.connect("completed", func() -> void: _fail_test_completed_fired = true)
	minigame_fail.connect("failed", func(reason: String) -> void:
		_failed_fired = true
		_fail_reason = reason
	)

	var target_fail: Array = minigame_fail.get("target")
	var wrong_idx: int = -1
	for i in range(target_fail.size()):
		if not target_fail[i]:
			wrong_idx = i
			break

	if wrong_idx == -1:
		print("FAIL: No false switch found in target")
		quit(1)
		return

	minigame_fail.call("toggle", wrong_idx)

	if not _failed_fired:
		await create_timer(0.05).timeout

	if not _failed_fired:
		print("FAIL: failed signal did not fire on wrong switch toggle")
		quit(1)
		return

	if _fail_test_completed_fired:
		print("FAIL: completed signal fired on wrong switch toggle")
		quit(1)
		return

	if _fail_reason.is_empty():
		print("FAIL: failed reason was empty")
		quit(1)
		return

	print("PASS")
	quit(0)
