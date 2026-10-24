extends Node

# CONTRACT STUB (Claude). T3a implements the bodies; do not change signatures.
# Records every death with the real-world spaceflight incident behind it.

signal entry_added(entry: Dictionary)

# cause_id -> {"title", "year", "summary", "lesson"}. Filled in by T3a.
const INCIDENTS := {}

var entries: Array[Dictionary] = []
var last_entry: Dictionary = {}


# Builds an entry from MalfunctionManager state + INCIDENTS, appends it to
# entries, persists via SaveData ("mission_log"), sets last_entry, emits
# entry_added and returns the entry.
func record_death(cause_id: String, kind: String, detail: String) -> Dictionary:
	return {}


func incident_for(cause_id: String) -> Dictionary:
	return INCIDENTS.get(cause_id, {})
