extends SceneTree

var _completed_fired: bool = false


func _initialize() -> void:
	var scene := load("res://scenes/minigames/power_switches.tscn") as PackedScene
	if scene == null:
		print("FAIL: Failed to load power switches scene")
		quit(1)
		return

	var minigame := scene.instantiate() as PowerSwitches
	if minigame == null:
		print("FAIL: Failed to instantiate power switches scene")
		quit(1)
		return

	root.add_child(minigame)
	await process_frame

	if minigame.target.size() != 6:
		print("FAIL: target size should be 6")
		quit(1)
		return

	if minigame.switches.size() != 6:
		print("FAIL: switches size should be 6")
		quit(1)
		return

	var true_count: int = 0
	for val: bool in minigame.target:
		if val:
			true_count += 1
	if true_count < 2 or true_count > 4:
		print("FAIL: target must have at least 2 true and at least 2 false")
		quit(1)
		return

	for val: bool in minigame.switches:
		if val:
			print("FAIL: switches should start all false")
			quit(1)
			return

	minigame.completed.connect(func() -> void: _completed_fired = true)

	for i in range(minigame.target.size()):
		if minigame.target[i]:
			minigame.toggle(i)

	await create_timer(0.5).timeout

	if not _completed_fired:
		print("FAIL: completed signal did not fire")
		quit(1)
		return

	print("PASS")
	quit(0)
