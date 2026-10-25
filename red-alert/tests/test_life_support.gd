extends SceneTree

var _critical_events: Array[String] = []


func _fail(reason: String) -> void:
	print("FAIL: " + reason)
	quit(1)


func _initialize() -> void:
	await process_frame

	var ls: Node = root.get_node_or_null("LifeSupport")
	if ls == null:
		var ls_script := load("res://scripts/systems/life_support.gd") as GDScript
		if ls_script == null:
			return _fail("Failed to load life_support.gd")
		ls = ls_script.new()
		root.add_child(ls)
		await process_frame

	var mm: Node = root.get_node_or_null("MalfunctionManager")
	if mm == null:
		var mm_script := load("res://scripts/systems/malfunction_manager.gd") as GDScript
		if mm_script == null:
			return _fail("Failed to load malfunction_manager.gd")
		mm = mm_script.new()
		root.add_child(mm)
		await process_frame

	ls.connect("level_critical", func(id: String) -> void:
		_critical_events.append(id)
	)

	mm.call("start_run")
	mm.call("trigger", "power")

	var malfunctions: Dictionary = mm.get("MALFUNCTIONS")
	var power_limit: float = float(malfunctions["power"]["time_limit"])
	mm.set("time_left", power_limit * 0.1)

	await create_timer(3.0).timeout

	var power_val: float = float(ls.call("get_level", "power"))
	if not (power_val < 0.5):
		return _fail("Expected power < 0.5, got %f" % power_val)

	var co2_val: float = float(ls.call("get_level", "co2"))
	if not (co2_val > 0.4):
		return _fail("Expected co2 > 0.4, got %f" % co2_val)

	var is_crit_power: bool = bool(ls.call("is_critical", "power"))
	if not is_crit_power:
		return _fail("Expected is_critical('power') to be true")

	if not _critical_events.has("power"):
		return _fail("Expected level_critical to fire for 'power'")

	mm.call("fix", "power")

	await create_timer(4.0).timeout

	var power_after: float = float(ls.call("get_level", "power"))
	if not (power_after > 0.5):
		return _fail("Expected power > 0.5 after recovery, got %f" % power_after)

	print("PASS")
	quit(0)
