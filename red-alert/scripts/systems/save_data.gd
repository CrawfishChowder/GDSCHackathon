# Persistent key/value store backed by user://save.json.
# Provides global state persistence (settings, logs, achievements, stats) across restarts.
# Used by Settings, MissionLog, Achievements, and UI screens.
extends Node

const SAVE_PATH := "user://save.json"

var _data: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var json: JSON = JSON.new()
	var err: Error = json.parse(file.get_as_text())
	if err == OK and json.data is Dictionary:
		_data = json.data as Dictionary


func get_value(key: String, default: Variant = null) -> Variant:
	return _data.get(key, default)


func set_value(key: String, value: Variant) -> void:
	_data[key] = value
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(_data, "\t"))


# Atomically increments an integer key and persists the updated value to disk.
func increment(key: String) -> int:
	var value: int = int(get_value(key, 0)) + 1
	set_value(key, value)
	return value
