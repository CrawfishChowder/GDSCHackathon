class_name ShiftGrade
extends RefCounted


static func compute(fixes: int, close_calls: int, practice_mistakes: int, survived_seconds: float, completed: bool) -> Dictionary:
	var raw_score: int = fixes * 15 + (40 if completed else 0) - close_calls * 5 - practice_mistakes * 10 + int(survived_seconds / 10.0)
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
	if close_calls > 0:
		notes.append("%d close calls" % close_calls)
	if practice_mistakes > 0:
		notes.append("%d practice mistakes" % practice_mistakes)

	return {
		"score": score,
		"grade": grade,
		"notes": notes,
	}
