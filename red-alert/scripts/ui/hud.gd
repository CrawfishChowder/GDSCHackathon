extends CanvasLayer

@onready var prompt_label: Label = $PromptLabel
@onready var game_over: CanvasLayer = get_node_or_null("GameOver")

var alert_label: Label
var stats_label: Label
var controls_panel: ControlsPanel = null
var controls_hint_label: Label = null
var _controls_hint: PanelContainer = null
var _controls_tween: Tween = null

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	_setup_alert_label(); _setup_stats_label(); _setup_controls_hint()
	_setup_controls_panel(); _setup_persistent_hint(); _apply_high_contrast(); _apply_hide_hud()
	add_child(load("res://scripts/ui/crisis_brief.gd").new())
	var s := get_node_or_null("/root/Settings")
	if s != null and s.has_signal("settings_changed"): s.settings_changed.connect(_on_settings_changed)
	var mm := _get_mm()
	if mm != null and mm.has_signal("run_started"): mm.run_started.connect(_on_run_started)

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey): return
	var key_ev := event as InputEventKey
	if not key_ev.pressed or key_ev.echo: return
	if key_ev.physical_keycode == KEY_H or key_ev.keycode == KEY_H:
		var mh := get_node_or_null("/root/MinigameHost")
		if (mh != null and mh.has_method("is_open") and mh.is_open()) or get_tree().paused: return
		get_viewport().set_input_as_handled(); toggle()

func toggle() -> void:
	if controls_panel != null: controls_panel.toggle()

func _process(_delta: float) -> void:
	var s := get_node_or_null("/root/Settings")
	var hide: bool = bool(s.get_setting("hide_hud")) if s != null and s.has_method("get_setting") else false
	var mm := _get_mm()
	if mm == null:
		if alert_label != null: alert_label.visible = false
		return
	var active_id: String = mm.active_id
	if active_id != "":
		var dname: String = mm.display_name(active_id) if mm.has_method("display_name") else (mm.MALFUNCTIONS[active_id].get("name", active_id) if (mm.get("MALFUNCTIONS") and mm.MALFUNCTIONS.has(active_id)) else active_id)
		var time_left: float = mm.time_left; var total_secs := int(ceil(maxf(0.0, time_left)))
		alert_label.text = "!! %s  %d:%02d !!" % [dname.to_upper(), total_secs / 60, total_secs % 60]
		alert_label.visible = (not hide) and (fposmod(time_left, 1.0) >= 0.5 if time_left < 10.0 else true)
	elif alert_label != null: alert_label.visible = false
	var shift_total := int(ceil(maxf(0.0, mm.shift_time_left())))
	stats_label.text = "SHIFT %d:%02d LEFT   FIXES %d" % [shift_total / 60, shift_total % 60, mm.fixes_count]; stats_label.visible = not hide

func set_prompt(text: String) -> void:
	var s := get_node_or_null("/root/Settings")
	var hide: bool = bool(s.get_setting("hide_hud")) if s != null and s.has_method("get_setting") else false
	prompt_label.visible = (not text.is_empty()) and (not hide)
	prompt_label.text = ("[E] " + text) if not text.is_empty() else ""

func _setup_alert_label() -> void:
	alert_label = Label.new()
	alert_label.name = "AlertLabel"; alert_label.anchors_preset = Control.PRESET_CENTER_TOP
	alert_label.anchor_left = 0.5; alert_label.anchor_right = 0.5; alert_label.offset_left = -400.0; alert_label.offset_top = 24.0; alert_label.offset_right = 400.0; alert_label.offset_bottom = 68.0
	alert_label.grow_horizontal = Control.GROW_DIRECTION_BOTH; alert_label.grow_vertical = Control.GROW_DIRECTION_END
	alert_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; alert_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	alert_label.mouse_filter = Control.MOUSE_FILTER_IGNORE; alert_label.visible = false
	alert_label.add_theme_font_size_override("font_size", 30); alert_label.add_theme_color_override("font_color", Color(1.0, 0.15, 0.15))
	add_child(alert_label)

func _setup_stats_label() -> void:
	stats_label = Label.new()
	stats_label.name = "StatsLabel"; stats_label.anchors_preset = Control.PRESET_TOP_LEFT
	stats_label.offset_left = 16.0; stats_label.offset_top = 16.0; stats_label.offset_right = 350.0; stats_label.offset_bottom = 40.0
	stats_label.mouse_filter = Control.MOUSE_FILTER_IGNORE; stats_label.text = "SHIFT 5:00 LEFT   FIXES 0"
	stats_label.add_theme_font_size_override("font_size", 16); stats_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	add_child(stats_label)

func _setup_controls_hint() -> void:
	_controls_hint = PanelContainer.new()
	_controls_hint.name = "ControlsHint"; _controls_hint.anchors_preset = Control.PRESET_BOTTOM_LEFT
	_controls_hint.anchor_top = 1.0; _controls_hint.anchor_bottom = 1.0; _controls_hint.offset_left = 16.0; _controls_hint.offset_bottom = -16.0
	_controls_hint.grow_vertical = Control.GROW_DIRECTION_BEGIN; _controls_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE; _controls_hint.visible = false
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.06, 0.08, 0.85); style.set_corner_radius_all(4); style.set_content_margin_all(8.0)
	_controls_hint.add_theme_stylebox_override("panel", style)
	var lbl := Label.new()
	lbl.name = "HintText"; lbl.text = "WASD move · Mouse look · E interact · Hold B breathe · Esc pause"
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE; lbl.add_theme_font_size_override("font_size", 16); lbl.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	_controls_hint.add_child(lbl); add_child(_controls_hint)

func _setup_controls_panel() -> void:
	controls_panel = ControlsPanel.new(); controls_panel.name = "ControlsPanel"; controls_panel.visible = false
	add_child(controls_panel)

func _setup_persistent_hint() -> void:
	controls_hint_label = Label.new()
	controls_hint_label.name = "ControlsHintLabel"; controls_hint_label.text = "H  controls"
	controls_hint_label.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	controls_hint_label.anchor_left = 1.0; controls_hint_label.anchor_right = 1.0; controls_hint_label.anchor_top = 1.0; controls_hint_label.anchor_bottom = 1.0
	controls_hint_label.offset_left = -160.0; controls_hint_label.offset_top = -36.0; controls_hint_label.offset_right = -16.0; controls_hint_label.offset_bottom = -16.0
	controls_hint_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN; controls_hint_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	controls_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; controls_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	controls_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE; controls_hint_label.add_theme_font_size_override("font_size", 14)
	controls_hint_label.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
	add_child(controls_hint_label)

func _on_run_started() -> void:
	var s := get_node_or_null("/root/Settings")
	var hide: bool = bool(s.get_setting("hide_hud")) if s != null and s.has_method("get_setting") else false
	var sd := get_node_or_null("/root/SaveData")
	var seen: bool = bool(sd.get_value("controls_seen", false)) if sd != null and sd.has_method("get_value") else false
	if not seen:
		if controls_panel != null and not hide: controls_panel.show_panel()
		if sd != null and sd.has_method("set_value"): sd.set_value("controls_seen", true)
	if _controls_hint == null or hide: return
	_controls_hint.visible = true; _controls_hint.modulate.a = 1.0
	if _controls_tween != null and _controls_tween.is_valid(): _controls_tween.kill()
	_controls_tween = create_tween()
	if _controls_tween != null:
		_controls_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS); _controls_tween.tween_interval(7.0)
		_controls_tween.tween_property(_controls_hint, "modulate:a", 0.0, 0.5)
		_controls_tween.tween_callback(func() -> void: if is_instance_valid(_controls_hint): _controls_hint.visible = false)

func _apply_hide_hud() -> void:
	var s := get_node_or_null("/root/Settings")
	var hide: bool = bool(s.get_setting("hide_hud")) if s != null and s.has_method("get_setting") else false
	for n in [prompt_label, alert_label, stats_label, _controls_hint, controls_hint_label]:
		if n != null and hide: n.visible = false
	if controls_panel != null and hide: controls_panel.hide_panel()
	if not hide:
		if stats_label != null: stats_label.visible = true
		if controls_hint_label != null: controls_hint_label.visible = true

func _apply_high_contrast() -> void:
	var s := get_node_or_null("/root/Settings")
	var hc: bool = bool(s.get_setting("high_contrast")) if s != null and s.has_method("get_setting") else false
	var outline := 8 if hc else 0
	var update_lbl := func(lbl: Label, sz: int) -> void:
		if lbl != null:
			lbl.add_theme_font_size_override("font_size", sz)
			lbl.add_theme_constant_override("outline_size", outline); lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	update_lbl.call(alert_label, 38 if hc else 30)
	update_lbl.call(stats_label, 20 if hc else 16)
	if _controls_hint != null: update_lbl.call(_controls_hint.get_node_or_null("HintText") as Label, 20 if hc else 16)
	update_lbl.call(controls_hint_label, 18 if hc else 14)

func _on_settings_changed(key: String, _val: Variant) -> void:
	if key == "high_contrast": _apply_high_contrast()
	elif key == "hide_hud": _apply_hide_hud()

func _get_mm() -> Node:
	return get_node("/root/MalfunctionManager") if has_node("/root/MalfunctionManager") else null
