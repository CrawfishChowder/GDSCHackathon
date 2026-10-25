extends Node

signal malfunction_started(id: String, display_name: String, time_limit: float)
signal malfunction_fixed(id: String)
signal player_died(cause_id: String, display_name: String)
signal shift_completed
signal run_started
signal practice_mistake(cause_id: String, detail: String)

# One demo "shift". Survive this long (with nothing broken) to win.
const SHIFT_LENGTH := 300.0

const MALFUNCTIONS := {
	"reactor": {"name": "Reactor meltdown", "time_limit": 45.0},
	"power": {"name": "Power failure", "time_limit": 40.0},
	"o2": {"name": "O2 depletion", "time_limit": 50.0},
	"co2": {"name": "CO2 buildup", "time_limit": 45.0},
}

# Deaths that are not a malfunction timing out.
const OTHER_CAUSES := {
	"do_not_press": "Pressed the button",
}

var mode: String = "normal"
var countdown_frozen: bool = false
var running: bool = false
var active_id: String = ""
var time_left: float = 0.0
var survived_seconds: float = 0.0
var fixes_count: int = 0
# How the last run ended: "timeout" (countdown ran out), "mistake" (failed a
# minigame) or "button". death_detail is a short player-facing explanation.
var death_kind: String = ""
var death_detail: String = ""

var _next_in: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	if not running:
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
	else:
		_next_in -= delta
		if _next_in <= 0.0:
			var keys := MALFUNCTIONS.keys()
			if not keys.is_empty():
				var random_id: String = keys[randi() % keys.size()]
				trigger(random_id)


func start_run() -> void:
	running = true
	active_id = ""
	time_left = 0.0
	countdown_frozen = false
	survived_seconds = 0.0
	fixes_count = 0
	death_kind = ""
	death_detail = ""
	_next_in = 10.0
	run_started.emit()


func stop_run() -> void:
	running = false
	active_id = ""
	time_left = 0.0


func trigger(id: String) -> void:
	if not running or active_id != "":
		return
	if not MALFUNCTIONS.has(id):
		return
	active_id = id
	var info: Dictionary = MALFUNCTIONS[id]
	var limit: float = float(info["time_limit"])
	var sw: Node = get_node_or_null("/root/SpaceWeather") if is_inside_tree() else null
	if sw != null and sw.has_method("difficulty_multiplier"):
		limit *= float(sw.difficulty_multiplier())
	if mode == "hard":
		limit *= 0.5
	time_left = limit
	malfunction_started.emit(id, String(info["name"]), time_left)


func fix(id: String) -> void:
	if active_id.is_empty() or id != active_id:
		return
	fixes_count += 1
	var fixed_id := active_id
	active_id = ""
	time_left = 0.0
	_next_in = max(8.0, randf_range(15.0, 30.0) * pow(0.9, fixes_count))
	malfunction_fixed.emit(fixed_id)


# Ends the run immediately. kind: "timeout", "mistake" or "button".
func kill(cause_id: String, kind: String, detail: String = "") -> void:
	if not running:
		return
	if mode == "practice" and kind != "button":
		practice_mistake.emit(cause_id, detail)
		if kind == "timeout":
			var info: Dictionary = MALFUNCTIONS.get(cause_id, {})
			time_left = float(info.get("time_limit", 45.0))
		return
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
		var info: Dictionary = MALFUNCTIONS[id]
		return String(info.get("name", ""))
	return String(OTHER_CAUSES.get(id, ""))
