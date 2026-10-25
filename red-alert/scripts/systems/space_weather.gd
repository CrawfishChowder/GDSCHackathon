# Queries NASA DONKI API for live solar flare data to modulate shift difficulty.
# Listened to by MalfunctionManager and Voice; falls back to cached/offline data.
extends Node

signal flare_loaded(flare: Dictionary)

var latest_flare: Dictionary = {}

var _http: HTTPRequest
var _connected: bool = false
var _wake_reported: bool = false
var _mid_shift_event_fired: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_connect_signals()
	_fetch_flare()


func _process(_delta: float) -> void:
	if not _connected:
		_connect_signals()
	var mm: Node = get_node_or_null("/root/MalfunctionManager")
	if mm == null or not bool(mm.get("running")) or _mid_shift_event_fired:
		return
	var class_type: String = String(latest_flare.get("class_type", ""))
	var is_storm: bool = class_type.begins_with("M") or class_type.begins_with("X")
	if is_storm and float(mm.get("survived_seconds")) >= 150.0 and String(mm.get("active_id")) == "":
		_mid_shift_event_fired = true
		if mm.has_method("trigger"):
			mm.trigger("power")
		var voice: Node = get_node_or_null("/root/Voice")
		if voice != null and voice.has_method("say"):
			voice.say("hal_flare_hit")


func _connect_signals() -> void:
	var mm: Node = get_node_or_null("/root/MalfunctionManager")
	if mm != null and mm.has_signal("run_started") and not mm.run_started.is_connected(_on_run_started):
		mm.run_started.connect(_on_run_started)
		_connected = true


func _on_run_started() -> void:
	_wake_reported = false
	_mid_shift_event_fired = false
	_report_wake()

func _fetch_flare() -> void:
	if DisplayServer.get_name() == "headless":
		_set_offline()
		return
	_http = HTTPRequest.new()
	_http.timeout = 8.0
	_http.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)
	var now: int = int(Time.get_unix_time_from_system())
	var start_date: String = Time.get_date_string_from_unix_time(now - 30 * 86400)
	var end_date: String = Time.get_date_string_from_unix_time(now)
	var env_key: String = OS.get_environment("NASA_API_KEY")
	var key: String = env_key if not env_key.is_empty() else "DEMO_KEY"
	var url: String = "https://api.nasa.gov/DONKI/FLR?startDate=%s&endDate=%s&api_key=%s" % [start_date, end_date, key]
	if _http.request(url) != OK:
		_set_offline()


func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		_set_offline()
		return
	var flare: Dictionary = parse_response(body.get_string_from_utf8())
	if flare.is_empty():
		_set_offline()
		return
	latest_flare = flare
	var sd: Node = get_node_or_null("/root/SaveData")
	if sd != null and sd.has_method("set_value"):
		sd.set_value("last_flare", flare)
	flare_loaded.emit(latest_flare)
	var mm: Node = get_node_or_null("/root/MalfunctionManager")
	if mm != null and bool(mm.get("running")):
		_report_wake()


func _set_offline() -> void:
	var sd: Node = get_node_or_null("/root/SaveData")
	var cached: Variant = sd.get_value("last_flare") if sd != null and sd.has_method("get_value") else null
	if cached is Dictionary and not (cached as Dictionary).is_empty():
		latest_flare = (cached as Dictionary).duplicate()
		latest_flare["source"] = "cached"
	else:
		latest_flare = {"class_type": "", "peak_time": "", "source": "offline"}
	flare_loaded.emit(latest_flare)
	var mm: Node = get_node_or_null("/root/MalfunctionManager")
	if mm != null and bool(mm.get("running")):
		_report_wake()

func _report_wake() -> void:
	if _wake_reported or latest_flare.is_empty():
		return
	_wake_reported = true
	var source: String = String(latest_flare.get("source", ""))
	var peak: String = String(latest_flare.get("peak_time", "")).replace("T", " ").replace("Z", "")
	var text: String = "Space weather feed offline. Assuming quiet solar conditions."
	if source == "live":
		text = "NASA DONKI space weather report. Latest solar flare: class %s, peaking %s UTC." % [latest_flare.get("class_type", ""), peak]
	elif source == "cached":
		text = "NASA DONKI feed unreachable. Last recorded solar flare: class %s, peaking %s UTC." % [latest_flare.get("class_type", ""), peak]
	var voice: Node = get_node_or_null("/root/Voice")
	if voice != null and voice.has_method("say_text"):
		voice.say_text("hal", text)

# Parses a DONKI FLR JSON array body; returns the most recent flare dict or {}.
func parse_response(body: String) -> Dictionary:
	var json: JSON = JSON.new()
	if json.parse(body) != OK or not (json.data is Array):
		return {}
	var list: Array = json.data as Array
	if list.is_empty():
		return {}

	var latest_entry: Dictionary = {}
	var latest_peak: String = ""
	for item: Variant in list:
		if item is Dictionary and (item as Dictionary).has("classType") and (item as Dictionary).has("peakTime"):
			var peak: String = String((item as Dictionary).get("peakTime", ""))
			if latest_entry.is_empty() or peak > latest_peak:
				latest_peak = peak
				latest_entry = item as Dictionary

	if latest_entry.is_empty():
		return {}

	return {
		"class_type": String(latest_entry.get("classType", "")),
		"peak_time": latest_peak,
		"source": "live",
	}


# X-class 0.8, M-class 0.9, otherwise 1.0. Scales malfunction time limits.
func difficulty_multiplier() -> float:
	var class_type: String = String(latest_flare.get("class_type", ""))
	if class_type.begins_with("X"):
		return 0.8
	elif class_type.begins_with("M"):
		return 0.9
	return 1.0
