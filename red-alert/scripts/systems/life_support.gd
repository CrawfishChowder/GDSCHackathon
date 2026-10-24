extends Node

# CONTRACT STUB (Claude). T4a implements the bodies; do not change signatures.
# Habitat gauges, 0.0-1.0. For o2 and power, 1.0 is healthy. For co2 and
# core_temp, 0.0 is healthy. Driven by MalfunctionManager.

signal level_critical(id: String)

const GAUGES := ["o2", "co2", "power", "core_temp"]

var levels: Dictionary = {"o2": 1.0, "co2": 0.0, "power": 1.0, "core_temp": 0.0}


func get_level(id: String) -> float:
	return float(levels.get(id, 0.0))


# o2/power below 0.25, or co2/core_temp above 0.75.
func is_critical(id: String) -> bool:
	return false
