# Habitat environmental status simulation (O2, CO2, power, and core temperature).
# Driven by MalfunctionManager failure states; emits level_critical for HUD warnings.
extends Node

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
	var mm: Node = _get_mm()
	if mm != null and mm.has_signal("run_started") and not mm.run_started.is_connected(_on_run_started):
		mm.run_started.connect(_on_run_started)

	var active: String = ""
	var p: float = 0.0

	if mm != null and String(mm.get("active_id")) != "":
		active = String(mm.get("active_id"))
		var limit: float = 45.0
		var malfs: Variant = mm.get("MALFUNCTIONS")
		if malfs is Dictionary and (malfs as Dictionary).has(active):
			var info: Variant = (malfs as Dictionary)[active]
			if info is Dictionary:
				limit = float((info as Dictionary).get("time_limit", 45.0))
		if limit > 0.0:
			var time_left: float = float(mm.get("time_left"))
			p = clampf(1.0 - time_left / limit, 0.0, 1.0)

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

	for g: String in GAUGES:
		var cur: float = float(levels.get(g, 0.0))
		var tgt: float = float(targets.get(g, 0.0))
		var rate: float = float(rates.get(g, 0.15))
		levels[g] = move_toward(cur, tgt, rate * delta)

		var crit: bool = is_critical(g)
		if crit and not bool(_was_critical.get(g, false)):
			_was_critical[g] = true
			level_critical.emit(g)
		elif not crit and bool(_was_critical.get(g, false)):
			_was_critical[g] = false


func get_level(id: String) -> float:
	return float(levels.get(id, 0.0))


# Returns true if gauge is in danger zone: o2/power < 0.25, or co2/core_temp > 0.75.
func is_critical(id: String) -> bool:
	var val: float = get_level(id)
	if id == "o2" or id == "power":
		return val < 0.25
	elif id == "co2" or id == "core_temp":
		return val > 0.75
	return false


# Restores all life support gauges to nominal resting levels.
func reset_healthy() -> void:
	levels["o2"] = 1.0
	levels["co2"] = 0.0
	levels["power"] = 1.0
	levels["core_temp"] = 0.0
	for g: String in GAUGES:
		_was_critical[g] = false


func _connect_mm() -> void:
	var mm: Node = _get_mm()
	if mm != null and mm.has_signal("run_started"):
		if not mm.run_started.is_connected(_on_run_started):
			mm.run_started.connect(_on_run_started)


func _on_run_started() -> void:
	reset_healthy()


func _get_mm() -> Node:
	return get_node_or_null("/root/MalfunctionManager")
