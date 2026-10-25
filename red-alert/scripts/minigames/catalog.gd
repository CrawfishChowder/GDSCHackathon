class_name MinigameCatalog
extends RefCounted

const VARIANTS := {
	"reactor": [
		"res://scenes/minigames/reactor_sequence.tscn",
		"res://scenes/minigames/reactor_valves.tscn",
	],
	"o2": [
		"res://scenes/minigames/o2_keypad.tscn",
		"res://scenes/minigames/o2_leak_seal.tscn",
	],
	"co2": [
		"res://scenes/minigames/co2_adapter.tscn",
		"res://scenes/minigames/co2_beds.tscn",
	],
	"dust_storm": [
		"res://scenes/minigames/dust_storm_power.tscn",
		"res://scenes/minigames/dust_panel_align.tscn",
	],
}


static func pick(id: String, last_path: String = "") -> String:
	if not VARIANTS.has(id):
		return ""

	var candidates: Array = VARIANTS[id]
	var available: Array[String] = []
	for candidate in candidates:
		var path: String = String(candidate)
		if ResourceLoader.exists(path):
			available.append(path)

	if available.is_empty():
		return ""

	if available.size() == 1:
		return available[0]

	var pool: Array[String] = []
	for path: String in available:
		if path != last_path:
			pool.append(path)

	if pool.is_empty():
		return available[randi() % available.size()]

	return pool[randi() % pool.size()]
