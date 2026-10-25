extends SceneTree

var got: Dictionary = {}


func _fail(reason: String) -> void:
	paused = false
	print("FAIL: " + reason)
	quit(1)


func _initialize() -> void:
	await process_frame

	# 1. SaveData edge case
	var sd: Node = root.get_node_or_null("SaveData")
	if sd == null:
		return _fail("SaveData autoload not found")
	var sd_val: Variant = sd.get_value("nonexistent_robustness_key_xyz", "safe_default")
	if String(sd_val) != "safe_default":
		return _fail("SaveData default fallback failed")

	# 2. Settings edge case: unknown key returns null without crashing
	var settings: Node = root.get_node_or_null("Settings")
	if settings == null:
		return _fail("Settings autoload not found")
	var unknown_setting: Variant = settings.get_setting("unknown_robustness_key_xyz")
	if unknown_setting != null:
		return _fail("Settings.get_setting with unknown key did not return null")

	# 3. MalfunctionManager edge case: fix() with no active malfunction is a no-op
	var mm: Node = root.get_node_or_null("MalfunctionManager")
	if mm == null:
		return _fail("MalfunctionManager autoload not found")
	if mm.has_signal("malfunction_fixed"):
		mm.malfunction_fixed.connect(func(id: String) -> void:
			got["malfunction_fixed"] = id
		)
	var prev_fixes: int = int(mm.get("fixes_count"))
	mm.fix("reactor")
	if got.has("malfunction_fixed"):
		return _fail("MalfunctionManager emitted malfunction_fixed with no active failure")
	if int(mm.get("fixes_count")) != prev_fixes:
		return _fail("MalfunctionManager incremented fixes_count with no active failure")

	# 4. MissionLog edge case: record_death with unknown cause still records
	var ml: Node = root.get_node_or_null("MissionLog")
	if ml == null:
		return _fail("MissionLog autoload not found")
	if ml.has_signal("entry_added"):
		ml.entry_added.connect(func(entry: Dictionary) -> void:
			got["entry_added"] = entry
		)
	var recorded: Dictionary = ml.record_death("unknown_cause_xyz", "timeout", "Test detail")
	if not got.has("entry_added"):
		return _fail("MissionLog did not emit entry_added for unknown cause")
	if String(recorded.get("cause_id", "")) != "unknown_cause_xyz":
		return _fail("MissionLog recorded wrong cause_id")

	# 5. Voice edge case: say with unknown id is a no-op
	var voice: Node = root.get_node_or_null("Voice")
	if voice == null:
		return _fail("Voice autoload not found")
	voice.say("unknown_voice_line_xyz_999")

	# 6. LifeSupport edge case: unknown gauge returns 0.0 and is_critical returns false
	var ls: Node = root.get_node_or_null("LifeSupport")
	if ls == null:
		return _fail("LifeSupport autoload not found")
	var ls_val: float = float(ls.get_level("unknown_gauge_xyz"))
	if ls_val != 0.0 or bool(ls.is_critical("unknown_gauge_xyz")):
		return _fail("LifeSupport unexpected value for unknown gauge")

	# 7. Stress edge case: is_breathing returns bool without crashing
	var stress: Node = root.get_node_or_null("Stress")
	if stress == null:
		return _fail("Stress autoload not found")
	var _is_b: bool = bool(stress.is_breathing())

	# 8. Sfx edge case: play and get_stream with unknown id return null
	var sfx: Node = root.get_node_or_null("Sfx")
	if sfx == null:
		return _fail("Sfx autoload not found")
	if sfx.play("unknown_sfx_xyz") != null or sfx.get_stream("unknown_sfx_xyz") != null:
		return _fail("Sfx did not return null for unknown sound effect")

	# 9. Achievements edge case: unknown achievement is not unlocked
	var ach: Node = root.get_node_or_null("Achievements")
	if ach == null:
		return _fail("Achievements autoload not found")
	if bool(ach.is_unlocked("unknown_achievement_xyz")):
		return _fail("Achievements reported unknown id as unlocked")
	ach.unlock("unknown_achievement_xyz")

	# 10. SpaceWeather edge case: invalid JSON returns empty dict
	var sw: Node = root.get_node_or_null("SpaceWeather")
	if sw == null:
		return _fail("SpaceWeather autoload not found")
	var parsed_flare: Dictionary = sw.parse_response("invalid json content")
	if not parsed_flare.is_empty():
		return _fail("SpaceWeather parsed invalid JSON as non-empty")

	# 11. PeopleInSpace edge case: invalid JSON returns false
	var pis: Node = root.get_node_or_null("PeopleInSpace")
	if pis == null:
		return _fail("PeopleInSpace autoload not found")
	var pis_ok: bool = bool(pis.parse_response("invalid json content"))
	if pis_ok:
		return _fail("PeopleInSpace parse_response returned true for invalid JSON")

	# 12. ShiftGrade edge case: negative values clamp to 0
	var grade_res: Dictionary = ShiftGrade.compute(-5, -2, -1, -50.0, false)
	var score: int = int(grade_res.get("score", -1))
	var grade_letter: String = String(grade_res.get("grade", ""))
	if score != 0 or grade_letter != "F":
		return _fail("ShiftGrade did not clamp negative values to score 0 and grade F")

	paused = false
	print("PASS")
	quit(0)
