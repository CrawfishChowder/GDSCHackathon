class_name SettingsPanel
extends VBoxContainer

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
var _updating: bool = false


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 10)
	_build_ui()
	_load_values()
	var s := get_node_or_null("/root/Settings")
	if s != null and s.has_signal("settings_changed"):
		s.settings_changed.connect(_on_settings_changed)


func _build_ui() -> void:
	var title := Label.new()
	title.text = "SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
	add_child(title)

	_sens_slider = HSlider.new(); _sens_val_label = Label.new()
	_add_slider_row("Mouse sensitivity", _sens_slider, _sens_val_label, 0.3, 2.5, 0.05, _on_sens_changed)
	_invert_btn = CheckButton.new()
	_add_check_button(_invert_btn, "Invert Y", _on_invert_toggled)
	_motion_btn = CheckButton.new()
	_add_check_button(_motion_btn, "Reduce motion (no head bob or camera shake)", _on_motion_toggled)
	_vol_slider = HSlider.new(); _vol_val_label = Label.new()
	_add_slider_row("Master volume", _vol_slider, _vol_val_label, 0.0, 1.0, 0.01, _on_vol_changed)
	_sfx_slider = HSlider.new(); _sfx_val_label = Label.new()
	_add_slider_row("Sound effects volume", _sfx_slider, _sfx_val_label, 0.0, 1.0, 0.01, _on_sfx_changed)
	_voice_slider = HSlider.new(); _voice_val_label = Label.new()
	_add_slider_row("Voice volume", _voice_slider, _voice_val_label, 0.0, 1.0, 0.01, _on_voice_changed)
	_captions_btn = CheckButton.new(); _add_check_button(_captions_btn, "Captions", _on_captions_toggled)
	_contrast_btn = CheckButton.new(); _add_check_button(_contrast_btn, "High contrast", _on_contrast_toggled)
	_shadows_btn = CheckButton.new(); _add_check_button(_shadows_btn, "Shadows (turn off on slow machines)", _on_shadows_toggled)
	_hide_hud_btn = CheckButton.new(); _add_check_button(_hide_hud_btn, "Hide HUD (for screenshots)", _on_hide_hud_toggled)


func _add_slider_row(label_text: String, slider: HSlider, val_label: Label, min_v: float, max_v: float, step_v: float, callback: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var lbl := Label.new()
	lbl.text = label_text; lbl.custom_minimum_size = Vector2(140, 0)
	row.add_child(lbl)
	slider.min_value = min_v; slider.max_value = max_v; slider.step = step_v
	slider.custom_minimum_size = Vector2(160, 0)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(callback)
	row.add_child(slider)
	val_label.custom_minimum_size = Vector2(50, 0)
	row.add_child(val_label)
	add_child(row)


func _add_check_button(btn: CheckButton, text: String, callback: Callable) -> void:
	btn.text = text
	btn.toggled.connect(callback)
	add_child(btn)


func _get_setting_val(key: String, default_val: Variant) -> Variant:
	var s := get_node_or_null("/root/Settings")
	if s != null and s.has_method("get_setting"):
		var val: Variant = s.get_setting(key)
		if val != null: return val
	return default_val


func _load_values() -> void:
	_updating = true
	var sens: float = float(_get_setting_val("mouse_sensitivity", 1.0))
	var vol: float = float(_get_setting_val("master_volume", 0.8))
	var sfx: float = float(_get_setting_val("sfx_volume", 1.0))
	var voice: float = float(_get_setting_val("voice_volume", 1.0))
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
	_updating = false


func _on_sens_changed(val: float) -> void:
	_sens_val_label.text = "%.2fx" % val
	if not _updating: _save_setting("mouse_sensitivity", val)

func _on_invert_toggled(pressed: bool) -> void:
	if not _updating: _save_setting("invert_y", pressed)

func _on_motion_toggled(pressed: bool) -> void:
	if not _updating: _save_setting("reduce_motion", pressed)

func _on_vol_changed(val: float) -> void:
	_vol_val_label.text = "%d%%" % roundi(val * 100.0)
	if not _updating: _save_setting("master_volume", val)

func _on_sfx_changed(val: float) -> void:
	_sfx_val_label.text = "%d%%" % roundi(val * 100.0)
	if not _updating: _save_setting("sfx_volume", val)

func _on_voice_changed(val: float) -> void:
	_voice_val_label.text = "%d%%" % roundi(val * 100.0)
	if not _updating: _save_setting("voice_volume", val)

func _on_captions_toggled(pressed: bool) -> void:
	if not _updating: _save_setting("captions", pressed)
func _on_contrast_toggled(pressed: bool) -> void:
	if not _updating: _save_setting("high_contrast", pressed)
func _on_shadows_toggled(pressed: bool) -> void:
	if not _updating: _save_setting("shadows", pressed)
func _on_hide_hud_toggled(pressed: bool) -> void:
	if not _updating: _save_setting("hide_hud", pressed)

func _save_setting(key: String, value: Variant) -> void:
	var s := get_node_or_null("/root/Settings")
	if s != null and s.has_method("set_setting"):
		s.set_setting(key, value)

func _on_settings_changed(_key: String, _val: Variant) -> void:
	_load_values()
