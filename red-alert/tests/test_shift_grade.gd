extends SceneTree


func _fail(reason: String) -> void:
	print("FAIL: " + reason)
	quit(1)


func _initialize() -> void:
	await process_frame

	var sg_script := load("res://scripts/systems/shift_grade.gd") as GDScript
	if sg_script == null:
		return _fail("Failed to load shift_grade.gd")

	# 1. compute(6, 0, 0, 300, true) -> A
	var res1: Dictionary = sg_script.compute(6, 0, 0, 300.0, true)
	if res1.get("grade") != "A":
		return _fail("expected grade 'A' for (6, 0, 0, 300, true), got '%s'" % String(res1.get("grade")))
	if int(res1.get("score")) != 100:
		return _fail("expected score 100 for (6, 0, 0, 300, true), got %d" % int(res1.get("score")))

	# 2. compute(0, 0, 0, 30, false) -> F
	var res2: Dictionary = sg_script.compute(0, 0, 0, 30.0, false)
	if res2.get("grade") != "F":
		return _fail("expected grade 'F' for (0, 0, 0, 30, false), got '%s'" % String(res2.get("grade")))
	if int(res2.get("score")) != 3:
		return _fail("expected score 3 for (0, 0, 0, 30, false), got %d" % int(res2.get("score")))

	# 3. Clamping at 0
	var res_clamp_low: Dictionary = sg_script.compute(0, 10, 5, 0.0, false)
	if int(res_clamp_low.get("score")) != 0:
		return _fail("expected score 0 clamped from negative, got %d" % int(res_clamp_low.get("score")))
	if res_clamp_low.get("grade") != "F":
		return _fail("expected grade 'F' for clamped score 0, got '%s'" % String(res_clamp_low.get("grade")))

	# 4. Clamping at 100
	var res_clamp_high: Dictionary = sg_script.compute(10, 0, 0, 300.0, true)
	if int(res_clamp_high.get("score")) != 100:
		return _fail("expected score 100 clamped from >100, got %d" % int(res_clamp_high.get("score")))
	if res_clamp_high.get("grade") != "A":
		return _fail("expected grade 'A' for clamped score 100, got '%s'" % String(res_clamp_high.get("grade")))

	# 5. Grade thresholds: A >= 85, B >= 70, C >= 55, D >= 40, F < 40
	var res_85: Dictionary = sg_script.compute(3, 0, 0, 0.0, true)
	if res_85.get("grade") != "A" or int(res_85.get("score")) != 85:
		return _fail("expected score 85 -> grade A, got %s (%d)" % [String(res_85.get("grade")), int(res_85.get("score"))])

	var res_84: Dictionary = sg_script.compute(2, 0, 0, 140.0, true)
	if res_84.get("grade") != "B" or int(res_84.get("score")) != 84:
		return _fail("expected score 84 -> grade B, got %s (%d)" % [String(res_84.get("grade")), int(res_84.get("score"))])

	var res_70: Dictionary = sg_script.compute(2, 0, 0, 0.0, true)
	if res_70.get("grade") != "B" or int(res_70.get("score")) != 70:
		return _fail("expected score 70 -> grade B, got %s (%d)" % [String(res_70.get("grade")), int(res_70.get("score"))])

	var res_69: Dictionary = sg_script.compute(1, 0, 0, 140.0, true)
	if res_69.get("grade") != "C" or int(res_69.get("score")) != 69:
		return _fail("expected score 69 -> grade C, got %s (%d)" % [String(res_69.get("grade")), int(res_69.get("score"))])

	var res_55: Dictionary = sg_script.compute(1, 0, 0, 0.0, true)
	if res_55.get("grade") != "C" or int(res_55.get("score")) != 55:
		return _fail("expected score 55 -> grade C, got %s (%d)" % [String(res_55.get("grade")), int(res_55.get("score"))])

	var res_54: Dictionary = sg_script.compute(0, 0, 0, 140.0, true)
	if res_54.get("grade") != "D" or int(res_54.get("score")) != 54:
		return _fail("expected score 54 -> grade D, got %s (%d)" % [String(res_54.get("grade")), int(res_54.get("score"))])

	var res_40: Dictionary = sg_script.compute(0, 0, 0, 0.0, true)
	if res_40.get("grade") != "D" or int(res_40.get("score")) != 40:
		return _fail("expected score 40 -> grade D, got %s (%d)" % [String(res_40.get("grade")), int(res_40.get("score"))])

	var res_39: Dictionary = sg_script.compute(0, 0, 0, 390.0, false)
	if res_39.get("grade") != "F" or int(res_39.get("score")) != 39:
		return _fail("expected score 39 -> grade F, got %s (%d)" % [String(res_39.get("grade")), int(res_39.get("score"))])

	# 6. Notes testing
	var res_notes: Dictionary = sg_script.compute(4, 2, 1, 0.0, true)
	var notes: Array = res_notes.get("notes", [])
	if not notes.has("Shift completed"):
		return _fail("expected notes to contain 'Shift completed'")
	if not notes.has("2 close calls"):
		return _fail("expected notes to contain '2 close calls'")
	if not notes.has("1 practice mistakes"):
		return _fail("expected notes to contain '1 practice mistakes'")

	print("PASS")
	quit(0)
