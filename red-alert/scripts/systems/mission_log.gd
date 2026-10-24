extends Node

# Records every death with the real-world spaceflight incident behind it.

signal entry_added(entry: Dictionary)

const INCIDENTS := {
	"reactor": {
		"title": "SL-1 reactor accident",
		"year": "1961",
		"summary": "At the SL-1 test reactor in Idaho, a control rod was withdrawn too far during maintenance. The reactor went prompt critical in milliseconds and all three operators were killed.",
		"lesson": "Reactor procedures exist because a single wrong movement is unrecoverable.",
	},
	"power": {
		"title": "Apollo 1 fire",
		"year": "1967",
		"summary": "During a launch rehearsal, a spark from damaged wiring ignited the pure-oxygen cabin of Apollo 1. Gus Grissom, Ed White and Roger Chaffee died within seconds.",
		"lesson": "In oxygen-rich air, one electrical fault can become a fire faster than anyone can react.",
	},
	"o2": {
		"title": "Soyuz 11 depressurization",
		"year": "1971",
		"summary": "As Soyuz 11 separated for re-entry, a valve opened and vented the cabin's air into space. Georgy Dobrovolsky, Vladislav Volkov and Viktor Patsayev are the only people to have died in space.",
		"lesson": "Breathable air is the thinnest margin a crew has.",
	},
	"do_not_press": {
		"title": "The Button",
		"year": "",
		"summary": "There is no real-world precedent. Every astronaut ever flown has managed not to press it.",
		"lesson": "Spaceflight checklists exist so nobody touches a control just to see what happens.",
	},
}

var entries: Array[Dictionary] = []
var last_entry: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var sd := _get_save_data()
	if sd != null:
		var raw_entries: Variant = sd.get_value("mission_log", [])
		if raw_entries is Array:
			entries.clear()
			for item: Variant in raw_entries:
				if item is Dictionary:
					entries.append(item)
			while entries.size() > 50:
				entries.pop_front()

	var mm := _get_mm()
	if mm != null:
		mm.player_died.connect(func(cause_id: String, _display_name: String) -> void:
			record_death(cause_id, String(mm.death_kind), String(mm.death_detail))
		)


func record_death(cause_id: String, kind: String, detail: String) -> Dictionary:
	var incident: Dictionary = incident_for(cause_id)
	var survived: float = 0.0
	var fixes_cnt: int = 0
	var mm := _get_mm()
	if mm != null:
		survived = float(mm.survived_seconds)
		fixes_cnt = int(mm.fixes_count)

	var entry: Dictionary = {
		"cause_id": cause_id,
		"kind": kind,
		"detail": detail,
		"title": String(incident.get("title", "")),
		"year": String(incident.get("year", "")),
		"summary": String(incident.get("summary", "")),
		"lesson": String(incident.get("lesson", "")),
		"survived_seconds": survived,
		"fixes": fixes_cnt,
		"unix_time": Time.get_unix_time_from_system(),
	}

	entries.append(entry)
	while entries.size() > 50:
		entries.pop_front()

	last_entry = entry

	var sd := _get_save_data()
	if sd != null:
		sd.set_value("mission_log", entries)

	entry_added.emit(entry)
	return entry


func incident_for(cause_id: String) -> Dictionary:
	return INCIDENTS.get(cause_id, {})


func _get_save_data() -> Node:
	if has_node("/root/SaveData"):
		return get_node("/root/SaveData")
	return null


func _get_mm() -> Node:
	if has_node("/root/MalfunctionManager"):
		return get_node("/root/MalfunctionManager")
	return null
