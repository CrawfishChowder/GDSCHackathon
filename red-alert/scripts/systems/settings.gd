extends Node

signal settings_changed(key: String, value: Variant)

const DEFAULTS := {
	"mouse_sensitivity": 1.0,
	"invert_y": false,
	"master_volume": 0.8,
	"captions": true,
	"high_contrast": false,
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var v: float = float(get_setting("master_volume"))
	AudioServer.set_bus_volume_db(0, linear_to_db(max(v, 0.0001)))


func get_setting(key: String) -> Variant:
	var sd := get_node_or_null("/root/SaveData")
	if sd != null and sd.has_method("get_value"):
		var settings: Variant = sd.get_value("settings")
		if settings is Dictionary and (settings as Dictionary).has(key):
			return (settings as Dictionary)[key]
	return DEFAULTS.get(key, null)


func set_setting(key: String, value: Variant) -> void:
	var sd := get_node_or_null("/root/SaveData")
	var dict: Dictionary = {}
	if sd != null and sd.has_method("get_value"):
		var existing: Variant = sd.get_value("settings")
		if existing is Dictionary:
			dict = (existing as Dictionary).duplicate()
	dict[key] = value
	if sd != null and sd.has_method("set_value"):
		sd.set_value("settings", dict)
	if key == "master_volume":
		var v: float = float(value)
		AudioServer.set_bus_volume_db(0, linear_to_db(max(v, 0.0001)))
	settings_changed.emit(key, value)
