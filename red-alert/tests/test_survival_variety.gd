extends SceneTree


func _fail(reason: String) -> void:
	paused = false
	print("FAIL: " + reason)
	quit(1)


func _initialize() -> void:
	await process_frame

	var sc_script: GDScript = load("res://scripts/ui/survival_card.gd") as GDScript
	if sc_script == null:
		return _fail("Failed to load survival_card.gd")

	var card: Node = sc_script.new()
	if card == null:
		return _fail("Failed to instantiate SurvivalCard")
	root.add_child(card)
	await process_frame

	var power_titles: Array[String] = [
		"Apollo 12 (1969)",
		"Skylab (1973)",
	]

	card.call("show_for", "power")
	var first_title: String = String(card.call("current_title"))
	if not power_titles.has(first_title):
		return _fail("First power title was '%s', expected one of %s" % [first_title, str(power_titles)])

	if not bool(card.call("is_showing")):
		return _fail("SurvivalCard was not showing after first show_for('power')")

	card.call("show_for", "power")
	var second_title: String = String(card.call("current_title"))
	if not power_titles.has(second_title):
		return _fail("Second power title was '%s', expected one of %s" % [second_title, str(power_titles)])

	if first_title == second_title:
		return _fail("Two consecutive show_for('power') calls returned identical title '%s'" % first_title)

	card.call("show_for", "power")
	var third_title: String = String(card.call("current_title"))
	if third_title == second_title:
		return _fail("Third power title '%s' matched second title" % third_title)
	if third_title != first_title:
		return _fail("Third power title '%s' did not rotate back to '%s'" % [third_title, first_title])

	var o2_titles: Array[String] = [
		"Apollo 13 (1970)",
		"Mir fire (1997)",
	]
	card.call("show_for", "o2")
	var o2_first: String = String(card.call("current_title"))
	if not o2_titles.has(o2_first):
		return _fail("First o2 title was '%s', expected one of %s" % [o2_first, str(o2_titles)])

	card.call("show_for", "o2")
	var o2_second: String = String(card.call("current_title"))
	if not o2_titles.has(o2_second):
		return _fail("Second o2 title was '%s', expected one of %s" % [o2_second, str(o2_titles)])
	if o2_first == o2_second:
		return _fail("Two consecutive show_for('o2') calls returned identical title '%s'" % o2_first)

	var reactor_titles: Array[String] = [
		"Kilopower KRUSTY test (2018)",
		"ISS ammonia leak (2013)",
	]
	card.call("show_for", "reactor")
	var reactor_first: String = String(card.call("current_title"))
	if not reactor_titles.has(reactor_first):
		return _fail("First reactor title was '%s', expected one of %s" % [reactor_first, str(reactor_titles)])

	card.call("show_for", "reactor")
	var reactor_second: String = String(card.call("current_title"))
	if not reactor_titles.has(reactor_second):
		return _fail("Second reactor title was '%s', expected one of %s" % [reactor_second, str(reactor_titles)])
	if reactor_first == reactor_second:
		return _fail("Two consecutive show_for('reactor') calls returned identical title '%s'" % reactor_first)

	card.call("show_for", "co2")
	var co2_title: String = String(card.call("current_title"))
	if co2_title != "Apollo 13 scrubber adapter (1970)":
		return _fail("co2 title was '%s', expected 'Apollo 13 scrubber adapter (1970)'" % co2_title)

	card.free()
	paused = false
	print("PASS")
	quit(0)
