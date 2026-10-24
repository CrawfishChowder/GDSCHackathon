extends Node

signal malfunction_started(id: String, display_name: String, time_limit: float)
signal malfunction_fixed(id: String)
signal player_died(cause_id: String, display_name: String)

const MALFUNCTIONS := {
	"reactor": {"name": "Reactor meltdown", "time_limit": 45.0},
	"power": {"name": "Power failure", "time_limit": 40.0},
	"o2": {"name": "O2 depletion", "time_limit": 50.0},
}

var running: bool = false
var active_id: String = ""
var time_left: float = 0.0
var survived_seconds: float = 0.0
var fixes_count: int = 0

var _next_in: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	if not running:
		return

	survived_seconds += delta

	if active_id != "":
		time_left -= delta
		if time_left <= 0.0:
			time_left = 0.0
			running = false
			var cause_id := active_id
			var dname := display_name(cause_id)
			player_died.emit(cause_id, dname)
			active_id = ""
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
	survived_seconds = 0.0
	fixes_count = 0
	_next_in = 10.0


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
	time_left = float(info["time_limit"])
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


func is_active(id: String) -> bool:
	return active_id == id and not id.is_empty()


static func display_name(id: String) -> String:
	if MALFUNCTIONS.has(id):
		var info: Dictionary = MALFUNCTIONS[id]
		return String(info.get("name", ""))
	return ""
