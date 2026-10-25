extends SceneTree

var got := {}


func _fail(reason: String) -> void:
	paused = false
	print("FAIL: " + reason)
	quit(1)


func _initialize() -> void:
	await process_frame

	var sd: Node = root.get_node_or_null("SaveData")
	if sd == null and ResourceLoader.exists("res://scripts/systems/save_data.gd"):
		var sd_script: GDScript = load("res://scripts/systems/save_data.gd") as GDScript
		if sd_script != null:
			sd = sd_script.new()
			sd.name = "SaveData"
			root.add_child(sd)
			await process_frame

	var st: Node = root.get_node_or_null("Settings")
	if st == null and ResourceLoader.exists("res://scripts/systems/settings.gd"):
		var st_script: GDScript = load("res://scripts/systems/settings.gd") as GDScript
		if st_script != null:
			st = st_script.new()
			st.name = "Settings"
			root.add_child(st)
			await process_frame

	var mm: Node = root.get_node_or_null("MalfunctionManager")
	if mm == null and ResourceLoader.exists("res://scripts/systems/malfunction_manager.gd"):
		var mm_script: GDScript = load("res://scripts/systems/malfunction_manager.gd") as GDScript
		if mm_script == null:
			return _fail("Failed to load malfunction_manager.gd")
		mm = mm_script.new()
		mm.name = "MalfunctionManager"
		root.add_child(mm)
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

	var pause_menu: Node = hud.get_node_or_null("PauseMenu")
	if pause_menu == null:
		pause_menu = hud.find_child("PauseMenu", true, false)
	if pause_menu == null:
		return _fail("PauseMenu not found in hud")

	var initial_open: bool = bool(pause_menu.call("is_open_menu"))
	if initial_open:
		return _fail("PauseMenu should not be open initially")
	if paused:
		return _fail("SceneTree should not be paused initially")

	# Test NOTIFICATION_APPLICATION_FOCUS_OUT
	pause_menu.on_focus_lost()
	await process_frame

	var is_open: bool = bool(pause_menu.call("is_open_menu"))
	if not is_open:
		return _fail("PauseMenu should be open after NOTIFICATION_APPLICATION_FOCUS_OUT")
	if not paused:
		return _fail("SceneTree should be paused after NOTIFICATION_APPLICATION_FOCUS_OUT")

	# Resume should unpause tree and close menu
	pause_menu.call("resume")
	await process_frame

	if paused:
		return _fail("SceneTree should be unpaused after calling resume")
	is_open = bool(pause_menu.call("is_open_menu"))
	if is_open:
		return _fail("PauseMenu should not be open after calling resume")

	# Test NOTIFICATION_WM_WINDOW_FOCUS_OUT
	pause_menu.on_focus_lost()
	await process_frame

	is_open = bool(pause_menu.call("is_open_menu"))
	if not is_open:
		return _fail("PauseMenu should be open after NOTIFICATION_WM_WINDOW_FOCUS_OUT")
	if not paused:
		return _fail("SceneTree should be paused after NOTIFICATION_WM_WINDOW_FOCUS_OUT")

	pause_menu.call("resume")
	await process_frame

	if paused:
		return _fail("SceneTree should be unpaused after calling resume (2nd)")

	# Test guard: do not open if tree is already paused
	paused = true
	pause_menu.on_focus_lost()
	await process_frame
	if bool(pause_menu.call("is_open_menu")):
		return _fail("PauseMenu should not open if tree is already paused")
	paused = false

	paused = false
	print("PASS")
	quit(0)
