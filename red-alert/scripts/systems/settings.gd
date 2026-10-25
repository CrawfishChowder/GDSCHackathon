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
	"fullscreen": false,
	"vsync": true,
	"show_fps": false,
	"ui_scale": 1.0,
}

var fps_layer: CanvasLayer
var fps_label: Label
var _fps_timer: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_fps_ui()
	_apply_fullscreen(bool(get_setting("fullscreen")))
	_apply_vsync(bool(get_setting("vsync")))
	_apply_ui_scale(float(get_setting("ui_scale")))
	_apply_show_fps(bool(get_setting("show_fps")))
	var v: float = float(get_setting("master_volume"))
	AudioServer.set_bus_volume_db(0, linear_to_db(max(v, 0.0001)))
	_apply_all_audio_volumes.call_deferred()


func _process(delta: float) -> void:
	if fps_label != null and fps_label.visible:
		_fps_timer += delta
		if _fps_timer >= 0.5:
			_fps_timer = 0.0
			fps_label.text = "%d FPS" % Engine.get_frames_per_second()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var ke := event as InputEventKey
		if ke.pressed and not ke.echo and (ke.physical_keycode == KEY_F11 or ke.keycode == KEY_F11):
			set_setting("fullscreen", not bool(get_setting("fullscreen")))
			var vp := get_viewport()
			if vp != null: vp.set_input_as_handled()


func _setup_fps_ui() -> void:
	if fps_layer != null: return
	fps_layer = CanvasLayer.new()
	fps_layer.name = "FPSLayer"
	fps_layer.layer = 40
	fps_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	fps_layer.visible = false
	add_child(fps_layer)

	fps_label = Label.new()
	fps_label.name = "FPSLabel"
	fps_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fps_label.anchors_preset = Control.PRESET_TOP_RIGHT
	fps_label.anchor_left = 1.0; fps_label.anchor_right = 1.0
	fps_label.anchor_top = 0.0; fps_label.anchor_bottom = 0.0
	fps_label.offset_left = -120.0; fps_label.offset_top = 8.0
	fps_label.offset_right = -12.0; fps_label.offset_bottom = 36.0
	fps_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	fps_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	fps_label.add_theme_font_size_override("font_size", 16)
	fps_label.visible = false
	fps_layer.add_child(fps_label)


func _apply_fullscreen(enabled: bool) -> void:
	if DisplayServer.get_name() != "headless":
		var m: DisplayServer.WindowMode = DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED
		DisplayServer.window_set_mode(m)


func _apply_vsync(enabled: bool) -> void:
	if DisplayServer.get_name() != "headless":
		var m: DisplayServer.VSyncMode = DisplayServer.VSYNC_ENABLED if enabled else DisplayServer.VSYNC_DISABLED
		DisplayServer.window_set_vsync_mode(m)


func _apply_ui_scale(scale_val: float) -> void:
	var tree := get_tree()
	if tree != null and tree.root != null: tree.root.content_scale_factor = scale_val


func _apply_show_fps(enabled: bool) -> void:
	if fps_layer == null: _setup_fps_ui()
	if fps_label != null:
		fps_label.visible = enabled
		if enabled: fps_label.text = "%d FPS" % Engine.get_frames_per_second()
	if fps_layer != null: fps_layer.visible = enabled
	_fps_timer = 0.0


func _apply_bus_volume(bus_name: String, v: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx != -1: AudioServer.set_bus_volume_db(idx, linear_to_db(max(v, 0.0001)))


func _apply_all_audio_volumes() -> void:
	_apply_bus_volume("SFX", float(get_setting("sfx_volume")))
	var voice_v: float = float(get_setting("voice_volume"))
	_apply_bus_volume("Voice", voice_v); _apply_bus_volume("Radio", voice_v)


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
		if existing is Dictionary: dict = (existing as Dictionary).duplicate()
	dict[key] = value
	if sd != null and sd.has_method("set_value"): sd.set_value("settings", dict)
	if key == "master_volume":
		AudioServer.set_bus_volume_db(0, linear_to_db(max(float(value), 0.0001)))
	elif key == "sfx_volume": _apply_bus_volume("SFX", float(value))
	elif key == "voice_volume":
		var v: float = float(value)
		_apply_bus_volume("Voice", v); _apply_bus_volume("Radio", v)
	elif key == "fullscreen": _apply_fullscreen(bool(value))
	elif key == "vsync": _apply_vsync(bool(value))
	elif key == "ui_scale": _apply_ui_scale(float(value))
	elif key == "show_fps": _apply_show_fps(bool(value))
	settings_changed.emit(key, value)
