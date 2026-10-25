extends SceneTree


func _fail(reason: String) -> void:
	print("FAIL: " + reason)
	quit(1)


func _initialize() -> void:
	await process_frame

	var sw_script := load("res://scripts/systems/space_weather.gd")
	var sw: Node = sw_script.new()

	# 1. parse_response on 2-entry array returns later flare's class_type; on "[]" and "oops" returns {}
	var sample_json: String = JSON.stringify([
		{"classType": "C2.4", "peakTime": "2026-10-10T12:00Z", "beginTime": "2026-10-10T11:30Z"},
		{"classType": "M4.5", "peakTime": "2026-10-22T08:15Z", "beginTime": "2026-10-22T07:50Z"},
	])
	var res_two: Dictionary = sw.call("parse_response", sample_json)
	if res_two.get("class_type", "") != "M4.5":
		return _fail("parse_response did not return later flare class_type: %s" % [res_two])
	if res_two.get("source", "") != "live":
		return _fail("parse_response source was not live: %s" % [res_two])

	var sample_rev: String = JSON.stringify([
		{"classType": "X1.1", "peakTime": "2026-10-24T18:00Z", "beginTime": "2026-10-24T17:30Z"},
		{"classType": "C5.2", "peakTime": "2026-10-01T04:00Z", "beginTime": "2026-10-01T03:30Z"},
	])
	var res_rev: Dictionary = sw.call("parse_response", sample_rev)
	if res_rev.get("class_type", "") != "X1.1":
		return _fail("parse_response reversed did not return later flare: %s" % [res_rev])

	var res_empty: Dictionary = sw.call("parse_response", "[]")
	if not res_empty.is_empty():
		return _fail("parse_response on '[]' did not return empty: %s" % [res_empty])

	var res_invalid: Dictionary = sw.call("parse_response", "oops")
	if not res_invalid.is_empty():
		return _fail("parse_response on 'oops' did not return empty: %s" % [res_invalid])

	# 2. difficulty_multiplier() after setting latest_flare to X2.1, M1.0, C3.0 gives 0.8, 0.9, 1.0
	sw.set("latest_flare", {"class_type": "X2.1"})
	var diff_x: float = float(sw.call("difficulty_multiplier"))
	if not is_equal_approx(diff_x, 0.8):
		return _fail("difficulty_multiplier for X2.1 was %f, expected 0.8" % diff_x)

	sw.set("latest_flare", {"class_type": "M1.0"})
	var diff_m: float = float(sw.call("difficulty_multiplier"))
	if not is_equal_approx(diff_m, 0.9):
		return _fail("difficulty_multiplier for M1.0 was %f, expected 0.9" % diff_m)

	sw.set("latest_flare", {"class_type": "C3.0"})
	var diff_c: float = float(sw.call("difficulty_multiplier"))
	if not is_equal_approx(diff_c, 1.0):
		return _fail("difficulty_multiplier for C3.0 was %f, expected 1.0" % diff_c)

	# 3. Voice.say_text("hal", "test") makes Voice.is_speaking() true
	var voice: Node = root.get_node_or_null("Voice")
	if voice == null:
		voice = load("res://scripts/systems/voice.gd").new()
		root.add_child(voice)
		await process_frame

	voice.call("say_text", "hal", "test")
	if not bool(voice.call("is_speaking")):
		return _fail("Voice.is_speaking() is false after calling say_text()")

	print("PASS")
	sw.free()
	quit(0)
