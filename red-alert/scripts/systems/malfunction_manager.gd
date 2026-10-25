# Central game-loop director managing shifts, failures, timers, and deaths.
# Listened to by HUD, Voice, LifeSupport, Stress, SFX, and Stage1 room controllers.
extends Node

signal malfunction_started(id: String, display_name: String, time_limit: float)
signal malfunction_fixed(id: String)
signal player_died(cause_id: String, display_name: String)
signal shift_completed
signal run_started
signal practice_mistake(cause_id: String, detail: String)

const SHIFT_LENGTH := 300.0
const MALFUNCTIONS := {
	"reactor": {"name": "Reactor meltdown", "time_limit": 45.0},
	"power": {"name": "Power failure", "time_limit": 40.0},
	"o2": {"name": "O2 depletion", "time_limit": 50.0},
	"co2": {"name": "CO2 buildup", "time_limit": 45.0},
	"dust_storm": {"name": "Dust storm", "time_limit": 50.0},
}
const OTHER_CAUSES := {"do_not_press": "Pressed the button"}
var mode: String = "normal"
var countdown_frozen: bool = false
var scripted: bool = false
var running: bool = false
var active_id: String = ""
var time_left: float = 0.0
var survived_seconds: float = 0.0
var fixes_count: int = 0
var close_calls: int = 0
var practice_mistakes: int = 0
var death_kind: String = ""
var death_detail: String = ""
var history: Array[Dictionary] = []
var _next_in: float = 0.0
var _last_id: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	if not running:
		return
	var tree: SceneTree = get_tree()
	if tree != null and tree.paused:
		var host: Node = get_node_or_null("/root/MinigameHost")
		if host == null or not host.is_open():
			return
	survived_seconds += delta
	if active_id != "":
		if not countdown_frozen:
			time_left -= delta
			if time_left <= 0.0:
				kill(active_id, "timeout", "The countdown ran out.")
	elif survived_seconds >= SHIFT_LENGTH:
		running = false
		shift_completed.emit()
	elif not scripted:
		_next_in -= delta
		if _next_in <= 0.0:
			var keys: Array = MALFUNCTIONS.keys()
			keys.erase(_last_id)
			if not keys.is_empty():
				trigger(String(keys[randi() % keys.size()]))

func start_run() -> void:
	running = true
	countdown_frozen = false
	active_id = ""
	death_kind = ""
	death_detail = ""
	time_left = 0.0
	survived_seconds = 0.0
	fixes_count = 0
	close_calls = 0
	practice_mistakes = 0
	history = []
	_next_in = 10.0
	scripted = (mode == "story")
	run_started.emit()

func stop_run() -> void:
	running = false
	active_id = ""
	time_left = 0.0

# Starts a specific malfunction, scaling its timer by difficulty and space weather.
func trigger(id: String) -> void:
	if not running or active_id != "" or not MALFUNCTIONS.has(id):
		return
	active_id = id
	_last_id = id
	var info: Dictionary = MALFUNCTIONS[id]
	var limit: float = float(info["time_limit"])
	if is_inside_tree():
		var sw: Node = get_node_or_null("/root/SpaceWeather")
		if sw != null and sw.has_method("difficulty_multiplier"):
			limit *= float(sw.difficulty_multiplier())
	if mode == "hard":
		limit *= 0.5
	time_left = limit
	history.append({"id": id, "name": display_name(id), "start": survived_seconds, "end": -1.0, "outcome": "active"})
	malfunction_started.emit(id, String(info["name"]), time_left)

# Resolves the active malfunction; no-op if no matching malfunction is active.
func fix(id: String) -> void:
	if active_id.is_empty() or id != active_id:
		return
	if time_left < 10.0:
		close_calls += 1
	fixes_count += 1
	var fixed_id: String = active_id
	active_id = ""
	time_left = 0.0
	_next_in = max(8.0, randf_range(15.0, 30.0) * pow(0.9, fixes_count))
	for i in range(history.size() - 1, -1, -1):
		if history[i].get("outcome") == "active":
			history[i]["end"] = survived_seconds
			history[i]["outcome"] = "fixed"
			break
	malfunction_fixed.emit(fixed_id)

# Ends the run immediately (or records a practice mistake in practice mode).
func kill(cause_id: String, kind: String, detail: String = "") -> void:
	if not running:
		return
	if mode == "practice" and kind != "button":
		practice_mistakes += 1
		practice_mistake.emit(cause_id, detail)
		if kind == "timeout":
			time_left = float(MALFUNCTIONS.get(cause_id, {}).get("time_limit", 45.0))
		history.append({"id": cause_id, "name": display_name(cause_id), "start": survived_seconds, "end": survived_seconds, "outcome": "practice_mistake"})
		return
	if not history.is_empty() and history[history.size() - 1].get("outcome") == "active":
		history[history.size() - 1]["end"] = survived_seconds
		history[history.size() - 1]["outcome"] = "fatal"
	running = false
	death_kind = kind
	death_detail = detail
	active_id = ""
	time_left = 0.0
	player_died.emit(cause_id, display_name(cause_id))

func shift_time_left() -> float:
	return max(0.0, SHIFT_LENGTH - survived_seconds)
func is_active(id: String) -> bool:
	return active_id == id and not id.is_empty()
static func display_name(id: String) -> String:
	if MALFUNCTIONS.has(id):
		return String(MALFUNCTIONS[id].get("name", ""))
	return String(OTHER_CAUSES.get(id, ""))
