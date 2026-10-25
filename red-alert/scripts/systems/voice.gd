extends Node

const VOICE_LINES_PATH := "res://data/voice_lines.json"

var lines: Dictionary = {}
var caption_layer: CanvasLayer
var caption_panel: PanelContainer
var caption_label: Label
var _caption_style: StyleBoxFlat
var _audio_player: AudioStreamPlayer
var _queue: Array[Dictionary] = []
var _is_playing: bool = false
var _play_token: int = 0
var _warning_10_fired: bool = false
var _connected: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS; _load_lines()
	_audio_player = AudioStreamPlayer.new(); _audio_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_audio_player); _setup_caption_ui(); _connect_signals()

func _process(_delta: float) -> void:
	if not _connected: _connect_signals()
	var mm := get_node_or_null("/root/MalfunctionManager")
	if mm != null and mm.running and mm.active_id != "":
		if mm.time_left < 10.0 and not _warning_10_fired:
			_warning_10_fired = true; say("hal_warning_10")
	elif mm == null or mm.active_id == "":
		_warning_10_fired = false

func say(line_id: String) -> void:
	if not lines.has(line_id): return
	var d: Dictionary = lines.get(line_id, {})
	_queue.append({"id": line_id, "speaker": String(d.get("speaker", "hal")), "text": String(d.get("text", ""))})
	if not _is_playing: _play_next()

func say_text(speaker: String, text: String) -> void:
	if text.is_empty(): return
	_queue.append({"id": "", "speaker": speaker, "text": text}); if not _is_playing: _play_next()

func is_speaking() -> bool: return _is_playing or not _queue.is_empty()

func _load_lines() -> void:
	if not FileAccess.file_exists(VOICE_LINES_PATH): return
	var file := FileAccess.open(VOICE_LINES_PATH, FileAccess.READ)
	if file != null:
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		if parsed is Dictionary: lines = parsed

func _setup_caption_ui() -> void:
	caption_layer = CanvasLayer.new(); caption_layer.layer = 15; caption_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(caption_layer)

	_caption_style = StyleBoxFlat.new()
	_caption_style.bg_color = Color(0.04, 0.06, 0.08, 0.85); _caption_style.set_content_margin_all(10.0)
	_caption_style.content_margin_left = 20.0; _caption_style.content_margin_right = 20.0; _caption_style.set_corner_radius_all(6)

	caption_panel = PanelContainer.new(); caption_panel.add_theme_stylebox_override("panel", _caption_style)
	caption_panel.anchors_preset = Control.PRESET_CENTER_BOTTOM
	caption_panel.anchor_left = 0.5; caption_panel.anchor_right = 0.5; caption_panel.anchor_top = 1.0; caption_panel.anchor_bottom = 1.0
	caption_panel.offset_left = -450.0; caption_panel.offset_right = 450.0; caption_panel.offset_bottom = -32.0
	caption_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH; caption_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	caption_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE; caption_panel.visible = false; caption_layer.add_child(caption_panel)

	caption_label = Label.new()
	caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; caption_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; caption_label.add_theme_font_size_override("font_size", 22)
	caption_label.mouse_filter = Control.MOUSE_FILTER_IGNORE; caption_panel.add_child(caption_label); _apply_settings()

func _apply_settings() -> void:
	var s := get_node_or_null("/root/Settings")
	var hc: bool = bool(s.get_setting("high_contrast")) if s != null and s.has_method("get_setting") else false
	var caps: bool = bool(s.get_setting("captions")) if s != null and s.has_method("get_setting") else true
	if _caption_style != null: _caption_style.bg_color = Color(0.0, 0.0, 0.0, 1.0) if hc else Color(0.04, 0.06, 0.08, 0.85)
	if caption_label != null: caption_label.add_theme_font_size_override("font_size", 28 if hc else 22)
	if not caps and caption_panel != null: caption_panel.visible = false

func _connect_signals() -> void:
	var s := get_node_or_null("/root/Settings")
	if s != null and s.has_signal("settings_changed") and not s.settings_changed.is_connected(_on_settings_changed):
		s.settings_changed.connect(_on_settings_changed)
	_apply_settings()
	var mm := get_node_or_null("/root/MalfunctionManager")
	if mm == null: return
	mm.run_started.connect(_on_run_started)
	mm.malfunction_started.connect(func(id: String, _dn: String, _lim: float) -> void:
		_warning_10_fired = false; say("hal_alarm_" + id); say("crew_hint_" + id)
	)
	mm.malfunction_fixed.connect(func(id: String) -> void: _warning_10_fired = false; say("crew_fixed_" + id))
	mm.player_died.connect(func(_c: String, _d: String) -> void:
		_queue.clear()
		if _audio_player != null: _audio_player.stop()
		_play_token += 1; _is_playing = false; say("hal_death")
	)
	mm.shift_completed.connect(func() -> void: say("crew_shift_done")); _connected = true

func _on_settings_changed(_k: String, _v: Variant) -> void: _apply_settings()

func _on_run_started() -> void:
	say("hal_wake"); say("crew_wake")
	var sd := get_node_or_null("/root/SaveData")
	if sd != null and sd.has_method("get_value") and int(sd.get_value("do_not_press_count", 0)) > 0: say("hal_welcome_back")

func _play_sfx(id: String, vol: float = 0.0, bus: String = "SFX") -> void:
	var sfx: Node = get_node_or_null("/root/Sfx")
	if sfx != null and sfx.has_method("play"): sfx.play(id, null, vol, bus)

func _play_next() -> void:
	if _queue.is_empty():
		_is_playing = false; caption_panel.visible = false; return
	_is_playing = true
	var token := _play_token
	var item: Dictionary = _queue.pop_front()
	var id: String = String(item.get("id", "")); var speaker: String = String(item.get("speaker", "hal"))
	var text: String = String(item.get("text", ""))

	caption_label.text = ("HAL: " if speaker == "hal" else "SAM (radio): ") + text
	var color := Color(0.55, 0.85, 1.0) if speaker == "hal" else Color(1.0, 0.8, 0.45)
	caption_label.add_theme_color_override("font_color", color)

	var s := get_node_or_null("/root/Settings")
	var caps: bool = bool(s.get_setting("captions")) if s != null and s.has_method("get_setting") else true
	caption_panel.visible = caps

	if speaker == "hal":
		_audio_player.bus = "Voice"
	else:
		_audio_player.bus = "Radio"; _play_sfx("static", -12.0, "SFX")

	var wait_sec := 1.2 + 0.06 * float(text.length())
	var played_audio := false
	if id != "":
		var mp3 := "res://assets/voice/%s.mp3" % id
		if ResourceLoader.exists(mp3):
			var stream := load(mp3) as AudioStream
			if stream != null:
				played_audio = true
				_audio_player.stream = stream
				if DisplayServer.get_name() != "headless":
					_audio_player.play(); await _audio_player.finished
				else:
					await get_tree().create_timer(0.05, true, false, true).timeout

	if not played_audio:
		await get_tree().create_timer(wait_sec, true).timeout

	if token == _play_token:
		if speaker != "hal": _play_sfx("static", -12.0, "SFX")
		_play_next()
