extends Node

# Habitat gauges, 0.0-1.0. For o2 and power, 1.0 is healthy. For co2 and
# core_temp, 0.0 is healthy. Driven by MalfunctionManager.

signal level_critical(id: String)

const GAUGES := ["o2", "co2", "power", "core_temp"]

var levels: Dictionary = {"o2": 1.0, "co2": 0.0, "power": 1.0, "core_temp": 0.0}

var _was_critical: Dictionary = {
	"o2": false,
	"co2": false,
	"power": false,
	"core_temp": false,
}


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	_connect_mm()


func _process(delta: float) -> void:
	var mm := _get_mm()
	if mm != null and mm.has_signal("run_started") and not mm.run_started.is_connected(_on_run_started):
		mm.run_started.connect(_on_run_started)

	var active: String = ""
	var p: float = 0.0

	if mm != null and mm.active_id != "":
		active = mm.active_id
		var limit: float = 45.0
		if mm.get("MALFUNCTIONS") and mm.MALFUNCTIONS.has(active):
			limit = float(mm.MALFUNCTIONS[active].get("time_limit", 45.0))
		if limit > 0.0:
			p = clampf(1.0 - mm.time_left / limit, 0.0, 1.0)

	var targets := {
		"o2": 1.0,
		"co2": 0.0,
		"power": 1.0,
		"core_temp": 0.0,
	}
	var rates := {
		"o2": 0.15,
		"co2": 0.15,
		"power": 0.15,
		"core_temp": 0.15,
	}

	if active == "o2":
		targets["o2"] = 1.0 - 0.9 * p
		rates["o2"] = 0.5
	elif active == "power":
		targets["power"] = 1.0 - 0.9 * p
		targets["co2"] = 0.9 * p
		rates["power"] = 0.5
		rates["co2"] = 0.5
	elif active == "reactor":
		targets["core_temp"] = 0.9 * p
		rates["core_temp"] = 0.5
	elif active == "co2":
		targets["co2"] = 0.9 * p
		targets["o2"] = 1.0 - 0.3 * p
		rates["co2"] = 0.5
		rates["o2"] = 0.5
	elif active == "dust_storm":
		targets["power"] = 1.0 - 0.8 * p
		rates["power"] = 0.5

	for g in GAUGES:
		var cur: float = float(levels.get(g, 0.0))
		var tgt: float = float(targets.get(g, 0.0))
		var rate: float = float(rates.get(g, 0.15))
		levels[g] = move_toward(cur, tgt, rate * delta)

		var crit: bool = is_critical(g)
		if crit and not _was_critical.get(g, false):
			_was_critical[g] = true
			level_critical.emit(g)
		elif not crit and _was_critical.get(g, false):
			_was_critical[g] = false


func get_level(id: String) -> float:
	return float(levels.get(id, 0.0))


# o2/power below 0.25, or co2/core_temp above 0.75.
func is_critical(id: String) -> bool:
	var val := get_level(id)
	if id == "o2" or id == "power":
		return val < 0.25
	elif id == "co2" or id == "core_temp":
		return val > 0.75
	return false


func reset_healthy() -> void:
	levels["o2"] = 1.0
	levels["co2"] = 0.0
	levels["power"] = 1.0
	levels["core_temp"] = 0.0
	for g in GAUGES:
		_was_critical[g] = false


func _connect_mm() -> void:
	var mm := _get_mm()
	if mm != null and mm.has_signal("run_started"):
		if not mm.run_started.is_connected(_on_run_started):
			mm.run_started.connect(_on_run_started)


func _on_run_started() -> void:
	reset_healthy()


func _get_mm() -> Node:
	if has_node("/root/MalfunctionManager"):
		return get_node("/root/MalfunctionManager")
	return null
