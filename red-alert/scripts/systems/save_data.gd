extends Node

# Tiny persistent key/value store (user://save.json). Survives restarts, so the
# game can remember things like how many times the player pressed the button.

const SAVE_PATH := "user://save.json"

var _data: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_data = parsed


func get_value(key: String, default: Variant = null) -> Variant:
	return _data.get(key, default)


func set_value(key: String, value: Variant) -> void:
	_data[key] = value
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(_data, "\t"))


func increment(key: String) -> int:
	var value := int(get_value(key, 0)) + 1
	set_value(key, value)
	return value
