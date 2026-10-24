extends Node

# Latest real solar flare from NASA DONKI (external API #1), with offline fallback.

# flare: {"class_type": "M1.2", "peak_time": "2026-10-20T13:45Z", "source": "live" | "offline"}
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
	var mm := get_node_or_null("/root/MalfunctionManager")
	if mm == null or not mm.running:
		return
	if not _mid_shift_event_fired:
		var class_type: String = String(latest_flare.get("class_type", ""))
		if (class_type.begins_with("M") or class_type.begins_with("X")) and mm.survived_seconds >= 150.0 and mm.active_id == "":
			_mid_shift_event_fired = true
			mm.trigger("power")
			var voice := get_node_or_null("/root/Voice")
			if voice != null and voice.has_method("say"):
				voice.say("hal_flare_hit")


func _connect_signals() -> void:
	var mm := get_node_or_null("/root/MalfunctionManager")
	if mm == null:
		return
	if not mm.run_started.is_connected(_on_run_started):
		mm.run_started.connect(_on_run_started)
	_connected = true


func _on_run_started() -> void:
	_wake_reported = false
	_mid_shift_event_fired = false
	_report_wake()


func _fetch_flare() -> void:
	# Headless runs are the test suite: never hit the API (DEMO_KEY is rate limited).
	if DisplayServer.get_name() == "headless":
		_set_offline()
		return
	_http = HTTPRequest.new()
	_http.timeout = 8.0
	_http.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)

	var now := int(Time.get_unix_time_from_system())
	var start_date := Time.get_date_string_from_unix_time(now - 30 * 86400)
	var end_date := Time.get_date_string_from_unix_time(now)
	var key := OS.get_environment("NASA_API_KEY")
	if key.is_empty():
		key = "DEMO_KEY"
	var url := "https://api.nasa.gov/DONKI/FLR?startDate=%s&endDate=%s&api_key=%s" % [start_date, end_date, key]
	if _http.request(url) != OK:
		_set_offline()


func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		_set_offline()
		return
	var flare := parse_response(body.get_string_from_utf8())
	if flare.is_empty():
		_set_offline()
		return
	latest_flare = flare
	flare_loaded.emit(latest_flare)
	var mm := get_node_or_null("/root/MalfunctionManager")
	if mm != null and mm.running:
		_report_wake()


func _set_offline() -> void:
	latest_flare = {"class_type": "", "peak_time": "", "source": "offline"}
	flare_loaded.emit(latest_flare)
	var mm := get_node_or_null("/root/MalfunctionManager")
	if mm != null and mm.running:
		_report_wake()


func _report_wake() -> void:
	if _wake_reported or latest_flare.is_empty():
		return
	_wake_reported = true
	var text := ""
	if latest_flare.get("source", "") == "live":
		var peak: String = String(latest_flare.get("peak_time", "")).replace("T", " ").replace("Z", "")
		text = "NASA DONKI space weather report. Latest solar flare: class %s, peaking %s UTC." % [
			latest_flare.get("class_type", ""),
			peak
		]
	else:
		text = "Space weather feed offline. Assuming quiet solar conditions."
	var voice := get_node_or_null("/root/Voice")
	if voice != null and voice.has_method("say_text"):
		voice.say_text("hal", text)


# Parses a DONKI FLR JSON array body; returns the most recent flare dict or {}.
func parse_response(body: String) -> Dictionary:
	var json := JSON.new()
	if json.parse(body) != OK:
		return {}
	var parsed: Variant = json.data
	if not (parsed is Array):
		return {}
	var list: Array = parsed as Array
	if list.is_empty():
		return {}

	var latest_entry: Dictionary = {}
	var latest_peak: String = ""
	for item: Variant in list:
		if not (item is Dictionary):
			continue
		var entry: Dictionary = item as Dictionary
		if not entry.has("classType") or not entry.has("peakTime"):
			continue
		var peak: String = String(entry.get("peakTime", ""))
		if latest_entry.is_empty() or peak > latest_peak:
			latest_peak = peak
			latest_entry = entry

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
	if class_type.begins_with("X"): return 0.8
	elif class_type.begins_with("M"): return 0.9
	return 1.0
