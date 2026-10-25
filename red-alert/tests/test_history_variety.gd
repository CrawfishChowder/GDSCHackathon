extends SceneTree

var got: Dictionary = {}


func _fail(reason: String) -> void:
	if root != null:
		paused = false
	print("FAIL: " + reason)
	quit(1)


func _initialize() -> void:
	await process_frame

	var voice: Node = root.get_node_or_null("Voice")
	if voice == null:
		var voice_script := load("res://scripts/systems/voice.gd") as GDScript
		if voice_script == null:
			return _fail("Failed to load voice.gd")
		voice = voice_script.new()
		voice.name = "Voice"
		root.add_child(voice)
		await process_frame

	var ml: Node = root.get_node_or_null("MissionLog")
	if ml == null:
		var ml_script := load("res://scripts/systems/mission_log.gd") as GDScript
		if ml_script == null:
			return _fail("Failed to load mission_log.gd")
		ml = ml_script.new()
		ml.name = "MissionLog"
		root.add_child(ml)
		await process_frame

	ml.connect("entry_added", func(entry: Dictionary) -> void:
		got["entry_added"] = entry
	)

	var valid_power_titles: Array[String] = [
		"Apollo 1 fire",
		"Soyuz T-10-1 launch pad fire",
	]
	var power_inc_1: Dictionary = ml.call("incident_for", "power")
	var title_1: String = String(power_inc_1.get("title", ""))
	if not valid_power_titles.has(title_1):
		return _fail("First incident_for('power') title '%s' not in expected power list" % title_1)

	var power_inc_2: Dictionary = ml.call("incident_for", "power")
	var title_2: String = String(power_inc_2.get("title", ""))
	if not valid_power_titles.has(title_2):
		return _fail("Second incident_for('power') title '%s' not in expected power list" % title_2)

	if title_1 == title_2:
		return _fail("Two consecutive calls to incident_for('power') returned identical title '%s'" % title_1)

	var power_inc_3: Dictionary = ml.call("incident_for", "power")
	var title_3: String = String(power_inc_3.get("title", ""))
	if title_3 == title_2:
		return _fail("Third incident_for('power') title '%s' matched second title" % title_3)
	if title_3 != title_1:
		return _fail("Third incident_for('power') title '%s' did not rotate back to '%s'" % [title_3, title_1])

	var co2_inc_1: Dictionary = ml.call("incident_for", "co2")
	var co2_title_1: String = String(co2_inc_1.get("title", ""))
	if co2_title_1 != "Apollo 13 CO2 crisis":
		return _fail("Expected co2 title 'Apollo 13 CO2 crisis', got '%s'" % co2_title_1)

	var co2_inc_2: Dictionary = ml.call("incident_for", "co2")
	var co2_title_2: String = String(co2_inc_2.get("title", ""))
	if co2_title_2 != "Apollo 13 CO2 crisis":
		return _fail("Second incident_for('co2') call changed title to '%s'" % co2_title_2)

	var valid_reactor_titles: Array[String] = [
		"SL-1 reactor accident",
		"Chernobyl reactor 4",
	]
	var reactor_1: Dictionary = ml.call("incident_for", "reactor")
	var reactor_2: Dictionary = ml.call("incident_for", "reactor")
	if not valid_reactor_titles.has(String(reactor_1.get("title", ""))):
		return _fail("Reactor incident 1 unexpected: %s" % String(reactor_1.get("title", "")))
	if not valid_reactor_titles.has(String(reactor_2.get("title", ""))):
		return _fail("Reactor incident 2 unexpected: %s" % String(reactor_2.get("title", "")))
	if String(reactor_1.get("title", "")) == String(reactor_2.get("title", "")):
		return _fail("Two consecutive reactor incidents did not differ")

	var valid_o2_titles: Array[String] = [
		"Soyuz 11 depressurization",
		"Apollo 13 oxygen tank",
	]
	var o2_1: Dictionary = ml.call("incident_for", "o2")
	var o2_2: Dictionary = ml.call("incident_for", "o2")
	if not valid_o2_titles.has(String(o2_1.get("title", ""))):
		return _fail("O2 incident 1 unexpected: %s" % String(o2_1.get("title", "")))
	if not valid_o2_titles.has(String(o2_2.get("title", ""))):
		return _fail("O2 incident 2 unexpected: %s" % String(o2_2.get("title", "")))
	if String(o2_1.get("title", "")) == String(o2_2.get("title", "")):
		return _fail("Two consecutive o2 incidents did not differ")

	var valid_dust_titles: Array[String] = [
		"Opportunity rover lost (2018)",
		"Spirit rover stranded",
	]
	var dust_1: Dictionary = ml.call("incident_for", "dust_storm")
	var dust_2: Dictionary = ml.call("incident_for", "dust_storm")
	if not valid_dust_titles.has(String(dust_1.get("title", ""))):
		return _fail("Dust storm incident 1 unexpected: %s" % String(dust_1.get("title", "")))
	if not valid_dust_titles.has(String(dust_2.get("title", ""))):
		return _fail("Dust storm incident 2 unexpected: %s" % String(dust_2.get("title", "")))
	if String(dust_1.get("title", "")) == String(dust_2.get("title", "")):
		return _fail("Two consecutive dust storm incidents did not differ")

	var entry: Dictionary = ml.call("record_death", "power", "mistake", "wiring spark")
	if entry.is_empty():
		return _fail("record_death returned empty dictionary")

	if not got.has("entry_added"):
		return _fail("entry_added signal was not recorded in got")

	var speaking: bool = bool(voice.call("is_speaking"))
	if not speaking:
		return _fail("Voice.is_speaking() was false after record_death")

	if root != null:
		paused = false
	print("PASS")
	quit(0)
