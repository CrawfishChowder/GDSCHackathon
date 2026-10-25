# Evaluates shift performance and assigns a letter grade (A-F) based on fixes and mistakes.
# Used by ShiftComplete win screen and MalfunctionManager to assess player skill.
class_name ShiftGrade
extends RefCounted


# Computes a 0-100 score and letter grade from run stats; clamps negative input metrics to 0.
static func compute(fixes: int, close_calls: int, practice_mistakes: int, survived_seconds: float, completed: bool) -> Dictionary:
	var safe_fixes: int = maxi(0, fixes)
	var safe_close_calls: int = maxi(0, close_calls)
	var safe_practice_mistakes: int = maxi(0, practice_mistakes)
	var safe_survived_seconds: float = maxf(0.0, survived_seconds)

	var completion_bonus: int = 0
	if completed:
		completion_bonus = 40

	var raw_score: int = safe_fixes * 15 + completion_bonus - safe_close_calls * 5 - safe_practice_mistakes * 10 + int(safe_survived_seconds / 10.0)
	var score: int = clampi(raw_score, 0, 100)

	var grade: String = "F"
	if score >= 85:
		grade = "A"
	elif score >= 70:
		grade = "B"
	elif score >= 55:
		grade = "C"
	elif score >= 40:
		grade = "D"

	var notes: Array[String] = []
	if completed:
		notes.append("Shift completed")
	if safe_close_calls > 0:
		notes.append("%d close calls" % safe_close_calls)
	if safe_practice_mistakes > 0:
		notes.append("%d practice mistakes" % safe_practice_mistakes)

	return {
		"score": score,
		"grade": grade,
		"notes": notes,
	}
