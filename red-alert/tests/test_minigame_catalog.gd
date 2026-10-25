extends SceneTree


func _fail(reason: String) -> void:
	paused = false
	print("FAIL: " + reason)
	quit(1)


func _initialize() -> void:
	await process_frame

	var catalog_script: GDScript = load("res://scripts/minigames/catalog.gd") as GDScript
	if catalog_script == null:
		return _fail("Failed to load catalog.gd")

	var reactor_paths: Array[String] = [
		"res://scenes/minigames/reactor_sequence.tscn",
		"res://scenes/minigames/reactor_valves.tscn",
	]

	var first_path: String = MinigameCatalog.pick("reactor", "")
	if not reactor_paths.has(first_path):
		return _fail("pick('reactor', '') returned '%s', expected one of %s" % [first_path, str(reactor_paths)])

	if ResourceLoader.exists("res://scenes/minigames/reactor_valves.tscn"):
		var second_path: String = MinigameCatalog.pick("reactor", first_path)
		if not reactor_paths.has(second_path):
			return _fail("pick('reactor', '%s') returned '%s', expected one of %s" % [first_path, second_path, str(reactor_paths)])
		if second_path == first_path:
			return _fail("pick('reactor', '%s') returned '%s', expected the second path" % [first_path, second_path])
		var third_path: String = MinigameCatalog.pick("reactor", second_path)
		if third_path != first_path:
			return _fail("pick('reactor', '%s') returned '%s', expected '%s'" % [second_path, third_path, first_path])
	else:
		var second_path: String = MinigameCatalog.pick("reactor", first_path)
		if second_path != first_path:
			return _fail("pick('reactor', '%s') with 1 variant returned '%s', expected '%s'" % [first_path, second_path, first_path])

	var unknown_path: String = MinigameCatalog.pick("unknown", "")
	if unknown_path != "":
		return _fail("pick('unknown', '') returned '%s', expected empty string" % unknown_path)

	var fs_script: GDScript = load("res://scripts/interaction/fix_station.gd") as GDScript
	if fs_script == null:
		return _fail("Failed to load fix_station.gd")

	var station: Node = fs_script.new()
	station.set("malfunction_id", "reactor")
	station.call("choose_variant")
	if String(station.get("_last_path")) != reactor_paths[0]:
		return _fail("First crisis should use the original minigame, got '%s'" % station.get("_last_path"))
	station.call("choose_variant")
	if String(station.get("_last_path")) != reactor_paths[1]:
		return _fail("Second crisis should switch to the variant, got '%s'" % station.get("_last_path"))
	station.call("choose_variant")
	if String(station.get("_last_path")) != reactor_paths[0]:
		return _fail("Third crisis should switch back, got '%s'" % station.get("_last_path"))
	station.free()

	var fallback_station: Node = fs_script.new()
	fallback_station.set("malfunction_id", "unhandled_cause")
	fallback_station.call("choose_variant")
	if String(fallback_station.get("_last_path")) != "":
		return _fail("FixStation set _last_path for unhandled malfunction")
	fallback_station.free()

	paused = false
	print("PASS")
	quit(0)
