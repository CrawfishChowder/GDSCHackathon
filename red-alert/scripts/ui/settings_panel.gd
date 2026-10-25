class_name SettingsPanel
extends VBoxContainer
# SettingsPanel provides controls for audio, gameplay, accessibility, and graphics.
# Writes changes to the Settings autoload and listens for external updates.

var _sens_slider: HSlider
var _sens_val_label: Label
var _invert_btn: CheckButton
var _motion_btn: CheckButton
var _vol_slider: HSlider
var _vol_val_label: Label
var _sfx_slider: HSlider
var _sfx_val_label: Label
var _voice_slider: HSlider
var _voice_val_label: Label
var _captions_btn: CheckButton
var _contrast_btn: CheckButton
var _shadows_btn: CheckButton
var _hide_hud_btn: CheckButton
var _fullscreen_btn: CheckButton
var _vsync_btn: CheckButton
var _fps_btn: CheckButton
var _scale_slider: HSlider
var _scale_val_label: Label
var _updating: bool = false

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 10)
	_build_ui()
	_load_values()
	var s: Node = get_node_or_null("/root/Settings")
	if s != null and s.has_signal("settings_changed"):
		s.connect("settings_changed", func(_k: String, _v: Variant) -> void: _load_values())

func _build_ui() -> void:
	var title := Label.new()
	title.text = "SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
	add_child(title)

	_sens_slider = HSlider.new(); _sens_val_label = Label.new()
	_add_slider("mouse_sensitivity", "Mouse sensitivity", _sens_slider, _sens_val_label, 0.3, 2.5, 0.05, false)
	_invert_btn = _add_check("invert_y", "Invert Y")
	_motion_btn = _add_check("reduce_motion", "Reduce motion (no head bob or camera shake)")
	_vol_slider = HSlider.new(); _vol_val_label = Label.new()
	_add_slider("master_volume", "Master volume", _vol_slider, _vol_val_label, 0.0, 1.0, 0.01, true)
	_sfx_slider = HSlider.new(); _sfx_val_label = Label.new()
	_add_slider("sfx_volume", "Sound effects volume", _sfx_slider, _sfx_val_label, 0.0, 1.0, 0.01, true)
	_voice_slider = HSlider.new(); _voice_val_label = Label.new()
	_add_slider("voice_volume", "Voice volume", _voice_slider, _voice_val_label, 0.0, 1.0, 0.01, true)
	_captions_btn = _add_check("captions", "Captions")
	_contrast_btn = _add_check("high_contrast", "High contrast")
	_shadows_btn = _add_check("shadows", "Shadows (turn off on slow machines)")
	_hide_hud_btn = _add_check("hide_hud", "Hide HUD (for screenshots)")
	_fullscreen_btn = _add_check("fullscreen", "Fullscreen (F11)")
	_vsync_btn = _add_check("vsync", "VSync")
	_fps_btn = _add_check("show_fps", "Show FPS")
	_scale_slider = HSlider.new(); _scale_val_label = Label.new()
	_add_slider("ui_scale", "Text / UI size", _scale_slider, _scale_val_label, 0.8, 1.5, 0.05, false)

func _add_slider(key: String, label_text: String, slider: HSlider, val_label: Label, min_v: float, max_v: float, step_v: float, is_pct: bool) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(140, 0)
	row.add_child(lbl)
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = step_v
	slider.custom_minimum_size = Vector2(160, 0)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(func(val: float) -> void:
		val_label.text = ("%d%%" % roundi(val * 100.0)) if is_pct else ("%.2fx" % val)
		if not _updating:
			_save_setting(key, val)
	)
	row.add_child(slider)
	val_label.custom_minimum_size = Vector2(50, 0)
	row.add_child(val_label)
	add_child(row)

func _add_check(key: String, text: String) -> CheckButton:
	var btn := CheckButton.new()
	btn.text = text
	btn.toggled.connect(func(pressed: bool) -> void:
		if not _updating:
			_save_setting(key, pressed)
	)
	add_child(btn)
	return btn

func _get_setting_val(key: String, default_val: Variant) -> Variant:
	var s: Node = get_node_or_null("/root/Settings")
	if s != null and s.has_method("get_setting"):
		var val: Variant = s.get_setting(key)
		if val != null:
			return val
	return default_val

func _load_values() -> void:
	_updating = true
	var sens: float = float(_get_setting_val("mouse_sensitivity", 1.0))
	var vol: float = float(_get_setting_val("master_volume", 0.8))
	var sfx: float = float(_get_setting_val("sfx_volume", 1.0))
	var voice: float = float(_get_setting_val("voice_volume", 1.0))
	var scale_v: float = float(_get_setting_val("ui_scale", 1.0))
	_sens_slider.value = sens; _sens_val_label.text = "%.2fx" % sens
	_invert_btn.button_pressed = bool(_get_setting_val("invert_y", false))
	_motion_btn.button_pressed = bool(_get_setting_val("reduce_motion", false))
	_vol_slider.value = vol; _vol_val_label.text = "%d%%" % roundi(vol * 100.0)
	_sfx_slider.value = sfx; _sfx_val_label.text = "%d%%" % roundi(sfx * 100.0)
	_voice_slider.value = voice; _voice_val_label.text = "%d%%" % roundi(voice * 100.0)
	_captions_btn.button_pressed = bool(_get_setting_val("captions", true))
	_contrast_btn.button_pressed = bool(_get_setting_val("high_contrast", false))
	_shadows_btn.button_pressed = bool(_get_setting_val("shadows", true))
	_hide_hud_btn.button_pressed = bool(_get_setting_val("hide_hud", false))
	_fullscreen_btn.button_pressed = bool(_get_setting_val("fullscreen", false))
	_vsync_btn.button_pressed = bool(_get_setting_val("vsync", true))
	_fps_btn.button_pressed = bool(_get_setting_val("show_fps", false))
	_scale_slider.value = scale_v; _scale_val_label.text = "%.2fx" % scale_v
	_updating = false

func _save_setting(key: String, value: Variant) -> void:
	var s: Node = get_node_or_null("/root/Settings")
	if s != null and s.has_method("set_setting"):
		s.set_setting(key, value)
