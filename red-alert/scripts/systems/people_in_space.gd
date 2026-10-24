extends Node

# Live "people in space right now" from Open Notify (external API #2).

signal loaded(count: int, names: Array)

const API_URL := "http://api.open-notify.org/astros.json"
const OFFLINE_FALLBACK := "Live crew data unavailable. More than 600 people have flown in space since 1961."

var count: int = -1
var names: Array[String] = []
var source: String = "pending"  # "pending" | "live" | "offline"

var _http: HTTPRequest


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	_fetch()


func _fetch() -> void:
	# Headless runs are the test suite: never hit the API.
	if DisplayServer.get_name() == "headless":
		source = "offline"
		return
	_http = HTTPRequest.new()
	_http.timeout = 8.0
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)
	var err := _http.request(API_URL)
	if err != OK:
		source = "offline"


func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		source = "offline"
		return
	var body_text := body.get_string_from_utf8()
	if not parse_response(body_text):
		source = "offline"


# Parses an Open Notify astros.json body; returns true on success and fills count/names.
func parse_response(body: String) -> bool:
	var json := JSON.new()
	var err := json.parse(body)
	if err != OK:
		return false
	var data = json.data
	if typeof(data) != TYPE_DICTIONARY:
		return false
	if data.has("message") and String(data["message"]) != "success":
		return false
	if not data.has("number") or not data.has("people"):
		return false
	if typeof(data["number"]) != TYPE_INT and typeof(data["number"]) != TYPE_FLOAT:
		return false
	if typeof(data["people"]) != TYPE_ARRAY:
		return false

	var parsed_names: Array[String] = []
	for item in data["people"]:
		if typeof(item) != TYPE_DICTIONARY or not item.has("name"):
			return false
		parsed_names.append(String(item["name"]))

	count = int(data["number"])
	names = parsed_names
	source = "live"
	loaded.emit(count, names)
	return true


# e.g. "Right now, 10 people are in space: A, B, C..." or an offline message.
func summary_line() -> String:
	if source != "live":
		return OFFLINE_FALLBACK

	var names_str := ""
	if names.size() <= 8:
		names_str = ", ".join(names)
	else:
		var shown: Array[String] = names.slice(0, 8)
		var remaining := names.size() - 8
		names_str = ", ".join(shown) + " and %d more" % remaining

	return "Right now, %d people are in space: %s." % [count, names_str]
