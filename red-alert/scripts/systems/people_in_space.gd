# Queries Open Notify API for live astronaut count and crew names in orbit.
# Listened to by HUD and title screen displays; falls back gracefully when offline.
extends Node

signal loaded(count: int, names: Array)

const API_URL := "http://api.open-notify.org/astros.json"
const OFFLINE_FALLBACK := "Live crew data unavailable. More than 600 people have flown in space since 1961."

var count: int = -1
var names: Array[String] = []
var source: String = "pending"

var _http: HTTPRequest


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	_fetch()


func _fetch() -> void:
	if DisplayServer.get_name() == "headless":
		source = "offline"
		return
	_http = HTTPRequest.new()
	_http.timeout = 8.0
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)
	var err: Error = _http.request(API_URL)
	if err != OK:
		source = "offline"


func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		source = "offline"
		return
	var body_text: String = body.get_string_from_utf8()
	if not parse_response(body_text):
		source = "offline"


# Parses an Open Notify astros.json body; returns true on success and fills count/names.
func parse_response(body: String) -> bool:
	var json: JSON = JSON.new()
	var err: Error = json.parse(body)
	if err != OK or not (json.data is Dictionary):
		return false
	var data: Dictionary = json.data as Dictionary
	if data.has("message") and String(data["message"]) != "success":
		return false
	if not data.has("number") or not data.has("people"):
		return false
	if not (data["number"] is int or data["number"] is float):
		return false
	if not (data["people"] is Array):
		return false

	var parsed_names: Array[String] = []
	for item: Variant in (data["people"] as Array):
		if not (item is Dictionary) or not (item as Dictionary).has("name"):
			return false
		parsed_names.append(String((item as Dictionary)["name"]))

	count = int(data["number"])
	names = parsed_names
	source = "live"
	loaded.emit(count, names)
	return true


# Returns a user-facing string detailing who is in orbit, or an offline disclaimer.
func summary_line() -> String:
	if source != "live":
		return OFFLINE_FALLBACK

	var names_str: String = ""
	if names.size() <= 8:
		names_str = ", ".join(names)
	else:
		var shown: Array[String] = names.slice(0, 8)
		var remaining: int = names.size() - 8
		names_str = ", ".join(shown) + " and %d more" % remaining

	return "Right now, %d people are in space: %s." % [count, names_str]
