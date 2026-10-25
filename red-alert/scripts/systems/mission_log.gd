# Archives death incidents and maps game failures to historical spaceflight disasters.
# Listened to by HUD (GameOver), Achievements, and the mission log UI via entry_added.
extends Node

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
		"summary": "During a launch rehearsal, a spark from damaged wiring ignited the pure-oxygen cabin of Apollo 1. Gus Grissom, Ed White and Roger Chaffee were killed in the fire.",
		"lesson": "In oxygen-rich air, one electrical fault can become a fire faster than anyone can react.",
	},
	"o2": {
		"title": "Soyuz 11 depressurization",
		"year": "1971",
		"summary": "As Soyuz 11 separated for re-entry, a valve opened and vented the cabin's air into space. Georgy Dobrovolsky, Vladislav Volkov and Viktor Patsayev are the only people to have died in space.",
		"lesson": "Breathable air is the thinnest margin a crew has.",
	},
	"co2": {
		"title": "Apollo 13 CO2 crisis",
		"year": "1970",
		"summary": "After the explosion, carbon dioxide rose toward dangerous levels in the lunar module because its round scrubber sockets could not take the command module's square cartridges. Ground engineers improvised an adapter in time. In your shift, nobody did.",
		"lesson": "Without scrubbing, a crew's own breath becomes the threat.",
	},
	"dust_storm": {
		"title": "Opportunity rover lost (2018)",
		"year": "2018",
		"summary": "In June 2018 a planet-wide dust storm blotted out the sun over the Opportunity rover's solar panels. Its batteries ran down and NASA never heard from it again; the mission was declared over in February 2019, about 15 years after landing.",
		"lesson": "On Mars, power depends on the weather, and a storm can last for months.",
	},
	"do_not_press": {
		"title": "The Button",
		"year": "",
		"summary": "There is no real-world precedent. Every astronaut ever flown has managed not to press it.",
		"lesson": "Spaceflight checklists exist so nobody touches a control just to see what happens.",
	},
}

const MORE_INCIDENTS := {
	"reactor": {
		"title": "Chernobyl reactor 4",
		"year": "1986",
		"summary": "During a safety test, operators ran Chernobyl's reactor 4 outside its safe limits. A power surge blew the reactor apart and started a fire, the worst nuclear accident in history.",
		"lesson": "Safety tests are only safe when the procedure's limits are respected.",
	},
	"power": {
		"title": "Soyuz T-10-1 launch pad fire",
		"year": "1983",
		"summary": "Fuel spilled and caught fire at the base of a Soyuz rocket seconds before launch. Ground controllers fired the escape tower, which pulled Vladimir Titov and Gennady Strekalov clear just before the rocket exploded.",
		"lesson": "Escape systems exist because fires spread faster than people can react.",
	},
	"o2": {
		"title": "Apollo 13 oxygen tank",
		"year": "1970",
		"summary": "Damaged wiring inside oxygen tank 2 sparked an explosion on the way to the Moon. The crew survived only by using the lunar module as a lifeboat.",
		"lesson": "One damaged wire in an oxygen system can end a mission.",
	},
	"dust_storm": {
		"title": "Spirit rover stranded",
		"year": "2010",
		"summary": "Spirit became stuck in soft sand and could not tilt its solar panels toward the winter sun. NASA last heard from it in March 2010.",
		"lesson": "On Mars, losing your angle to the sun can be fatal.",
	},
}

var entries: Array[Dictionary] = []
var last_entry: Dictionary = {}
var _last_titles: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var sd: Node = _get_save_data()
	if sd != null and sd.has_method("get_value"):
		var raw_entries: Variant = sd.get_value("mission_log", [])
		if raw_entries is Array:
			entries.clear()
			for item: Variant in (raw_entries as Array):
				if item is Dictionary:
					entries.append(item as Dictionary)
			while entries.size() > 50:
				entries.pop_front()

	var mm: Node = _get_mm()
	if mm != null and mm.has_signal("player_died"):
		mm.player_died.connect(func(cause_id: String, _display_name: String) -> void:
			record_death(cause_id, String(mm.get("death_kind")), String(mm.get("death_detail")))
		)


# Logs a casualty with historical context, persisting to SaveData (capped at 50).
func record_death(cause_id: String, kind: String, detail: String) -> Dictionary:
	var incident: Dictionary = incident_for(cause_id)
	var survived: float = 0.0
	var fixes_cnt: int = 0
	var mm: Node = _get_mm()
	if mm != null:
		survived = float(mm.get("survived_seconds"))
		fixes_cnt = int(mm.get("fixes_count"))

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

	var sd: Node = _get_save_data()
	if sd != null and sd.has_method("set_value"):
		sd.set_value("mission_log", entries)

	entry_added.emit(entry)

	var title: String = String(entry.get("title", ""))
	var year: String = String(entry.get("year", ""))
	if not title.is_empty():
		var voice: Node = _get_voice()
		if voice != null and voice.has_method("say_text"):
			var spoken_text: String = ""
			if year.is_empty():
				spoken_text = "Incident reference: %s." % title
			else:
				spoken_text = "Incident reference: %s, %s." % [title, year]
			voice.call("say_text", "hal", spoken_text)

	return entry


func incident_for(cause_id: String) -> Dictionary:
	var pool: Array[Dictionary] = []
	if INCIDENTS.has(cause_id):
		var inc_val: Variant = INCIDENTS[cause_id]
		if inc_val is Dictionary:
			pool.append(inc_val as Dictionary)
	if MORE_INCIDENTS.has(cause_id):
		var more_val: Variant = MORE_INCIDENTS[cause_id]
		if more_val is Dictionary:
			pool.append(more_val as Dictionary)

	if pool.is_empty():
		return {}

	if pool.size() == 1:
		var single: Dictionary = pool[0]
		_last_titles[cause_id] = String(single.get("title", ""))
		return single

	var last_title: String = String(_last_titles.get(cause_id, ""))
	var candidates: Array[Dictionary] = []
	for candidate: Dictionary in pool:
		if String(candidate.get("title", "")) != last_title:
			candidates.append(candidate)

	if candidates.is_empty():
		candidates = pool

	var chosen_idx: int = randi() % candidates.size()
	var chosen: Dictionary = candidates[chosen_idx]
	_last_titles[cause_id] = String(chosen.get("title", ""))
	return chosen


func _get_voice() -> Node:
	return get_node_or_null("/root/Voice")


func _get_save_data() -> Node:
	return get_node_or_null("/root/SaveData")


func _get_mm() -> Node:
	return get_node_or_null("/root/MalfunctionManager")
