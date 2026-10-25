extends Node

signal settings_changed(key: String, value: Variant)

const DEFAULTS := {
	"mouse_sensitivity": 1.0,
	"invert_y": false,
	"master_volume": 0.8,
	"captions": true,
	"high_contrast": false,
	"reduce_motion": false,
	"sfx_volume": 1.0,
	"voice_volume": 1.0,
	"shadows": true,
	"hide_hud": false,
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var v: float = float(get_setting("master_volume"))
	AudioServer.set_bus_volume_db(0, linear_to_db(max(v, 0.0001)))
	_apply_all_audio_volumes.call_deferred()


func _apply_bus_volume(bus_name: String, v: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx != -1:
		AudioServer.set_bus_volume_db(idx, linear_to_db(max(v, 0.0001)))


func _apply_all_audio_volumes() -> void:
	_apply_bus_volume("SFX", float(get_setting("sfx_volume")))
	var voice_v: float = float(get_setting("voice_volume"))
	_apply_bus_volume("Voice", voice_v)
	_apply_bus_volume("Radio", voice_v)


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
	elif key == "sfx_volume":
		_apply_bus_volume("SFX", float(value))
	elif key == "voice_volume":
		var v: float = float(value)
		_apply_bus_volume("Voice", v)
		_apply_bus_volume("Radio", v)
	settings_changed.emit(key, value)
