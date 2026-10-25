extends SceneTree


func _fail(reason: String) -> void:
	print("FAIL: " + reason)
	quit(1)


func _initialize() -> void:
	await process_frame

	var pis: Node = root.get_node_or_null("PeopleInSpace")
	if pis == null:
		var script_res := load("res://scripts/systems/people_in_space.gd") as GDScript
		if script_res == null:
			return _fail("Failed to load people_in_space.gd")
		pis = script_res.new()

	# Assert 1: "not json" returns false.
	var invalid_result: bool = pis.parse_response("not json")
	if invalid_result:
		return _fail("\"not json\" expected to return false, got true")

	# Assert 2: A 3-person body gives count == 3, source == "live", and a summary that contains all 3 names.
	var sample_3 := JSON.stringify({
		"message": "success",
		"number": 3,
		"people": [
			{"name": "Jasmin Moghbeli", "craft": "ISS"},
			{"name": "Andreas Mogensen", "craft": "ISS"},
			{"name": "Satoshi Furukawa", "craft": "ISS"}
		]
	})

	var ok_3: bool = pis.parse_response(sample_3)
	if not ok_3:
		return _fail("parse_response returned false for 3-person body")
	if int(pis.get("count")) != 3:
		return _fail("Expected count == 3, got %s" % str(pis.get("count")))
	if String(pis.get("source")) != "live":
		return _fail("Expected source == 'live', got '%s'" % str(pis.get("source")))

	var summary_3: String = pis.summary_line()
	if not summary_3.contains("Jasmin Moghbeli"):
		return _fail("3-person summary missing 'Jasmin Moghbeli': %s" % summary_3)
	if not summary_3.contains("Andreas Mogensen"):
		return _fail("3-person summary missing 'Andreas Mogensen': %s" % summary_3)
	if not summary_3.contains("Satoshi Furukawa"):
		return _fail("3-person summary missing 'Satoshi Furukawa': %s" % summary_3)

	# Assert 3: A 10-person body's summary contains "and 2 more".
	var sample_10 := JSON.stringify({
		"message": "success",
		"number": 10,
		"people": [
			{"name": "Astronaut 1", "craft": "ISS"},
			{"name": "Astronaut 2", "craft": "ISS"},
			{"name": "Astronaut 3", "craft": "ISS"},
			{"name": "Astronaut 4", "craft": "ISS"},
			{"name": "Astronaut 5", "craft": "ISS"},
			{"name": "Astronaut 6", "craft": "ISS"},
			{"name": "Astronaut 7", "craft": "ISS"},
			{"name": "Astronaut 8", "craft": "ISS"},
			{"name": "Astronaut 9", "craft": "CSS"},
			{"name": "Astronaut 10", "craft": "CSS"}
		]
	})

	var ok_10: bool = pis.parse_response(sample_10)
	if not ok_10:
		return _fail("parse_response returned false for 10-person body")
	if int(pis.get("count")) != 10:
		return _fail("Expected count == 10, got %s" % str(pis.get("count")))
	if String(pis.get("source")) != "live":
		return _fail("Expected source == 'live', got '%s'" % str(pis.get("source")))

	var summary_10: String = pis.summary_line()
	if not summary_10.contains("and 2 more"):
		return _fail("10-person summary expected to contain 'and 2 more': %s" % summary_10)

	if not pis.is_inside_tree():
		pis.free()

	print("PASS")
	quit(0)
