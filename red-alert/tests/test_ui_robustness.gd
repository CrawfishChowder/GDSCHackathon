# Tests UI robustness: GameOver double-restart guard, unpause safety,
# and PauseMenu open/close cycle stability.
extends SceneTree

var got := {}


func _fail(reason: String) -> void:
	paused = false
	print("FAIL: " + reason)
	quit(1)


func _ensure_autoload(node_name: String, path: String) -> Node:
	var n: Node = root.get_node_or_null(node_name)
	if n != null:
		return n
	if not ResourceLoader.exists(path):
		return null
	var res: Resource = load(path)
	if res is PackedScene:
		n = (res as PackedScene).instantiate()
	elif res is GDScript:
		n = (res as GDScript).new()
	if n != null:
		n.name = node_name
		root.add_child(n)
	return n


func _initialize() -> void:
	await process_frame

	_ensure_autoload("SaveData", "res://scripts/systems/save_data.gd")
	_ensure_autoload("Settings", "res://scripts/systems/settings.gd")
	_ensure_autoload("MalfunctionManager", "res://scripts/systems/malfunction_manager.gd")
	_ensure_autoload("MissionLog", "res://scripts/systems/mission_log.gd")
	_ensure_autoload("PeopleInSpace", "res://scripts/systems/people_in_space.gd")
	_ensure_autoload("Sfx", "res://scripts/systems/sfx.gd")
	await process_frame

	var hud_scene: PackedScene = load("res://scenes/ui/hud.tscn") as PackedScene
	if hud_scene == null:
		return _fail("Failed to load hud.tscn")
	var hud: Node = hud_scene.instantiate()
	if hud == null:
		return _fail("Failed to instantiate hud.tscn")
	root.add_child(hud)
	await process_frame
	await process_frame

	var game_over: Node = hud.get_node_or_null("GameOver")
	if game_over == null:
		game_over = hud.find_child("GameOver", true, false)
	if game_over == null:
		return _fail("GameOver node not found in hud")

	var pause_menu: Node = hud.get_node_or_null("PauseMenu")
	if pause_menu == null:
		pause_menu = hud.find_child("PauseMenu", true, false)
	if pause_menu == null:
		return _fail("PauseMenu node not found in hud")

	var mlog: Node = root.get_node_or_null("MissionLog")
	if mlog == null:
		return _fail("MissionLog autoload not found")

	# 1. Trigger death through MissionLog to present GameOver
	mlog.call("record_death", "o2", "mistake", "Soyuz 11 test casualty")
	await process_frame
	await process_frame

	if not bool(game_over.get("visible")):
		return _fail("GameOver screen should be visible after record_death")

	# 2. Call restart path twice quickly; verify no errors and double guard triggers
	game_over.call("restart")
	game_over.call("restart")
	await process_frame

	var leaving_flag: Variant = game_over.get("_leaving")
	if leaving_flag is bool and not (leaving_flag as bool):
		return _fail("GameOver _leaving guard should be true after restart")

	if paused:
		return _fail("SceneTree should be unpaused after restart")

	# 3. Reset GameOver visibility to test PauseMenu in clean state
	game_over.set("visible", false)
	paused = false
	await process_frame

	# 4. Cycle PauseMenu open and close 3 times; verify pause states
	for i: int in range(3):
		pause_menu.call("open_menu")
		await process_frame
		if not bool(pause_menu.call("is_open_menu")):
			return _fail("PauseMenu should be open in cycle %d" % i)
		if not paused:
			return _fail("SceneTree should be paused while PauseMenu is open (cycle %d)" % i)

		pause_menu.call("resume")
		await process_frame
		if bool(pause_menu.call("is_open_menu")):
			return _fail("PauseMenu should be closed after resume in cycle %d" % i)
		if paused:
			return _fail("SceneTree should be unpaused after resume in cycle %d" % i)

	# Clean up and conclude
	hud.queue_free()
	await process_frame

	paused = false
	print("PASS")
	quit(0)
