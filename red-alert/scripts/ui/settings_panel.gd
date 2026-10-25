class_name SettingsPanel
extends VBoxContainer

var _sens_slider: HSlider
var _sens_val_label: Label
var _invert_btn: CheckButton
var _vol_slider: HSlider
var _vol_val_label: Label
var _captions_btn: CheckButton
var _contrast_btn: CheckButton
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

	# Mouse sensitivity: HSlider 0.3 to 2.5 (step 0.05), showing "%.2fx"
	var sens_row := HBoxContainer.new()
	sens_row.add_theme_constant_override("separation", 8)
	var sens_lbl := Label.new()
	sens_lbl.text = "Mouse sensitivity"
	sens_lbl.custom_minimum_size = Vector2(140, 0)
	sens_row.add_child(sens_lbl)

	_sens_slider = HSlider.new()
	_sens_slider.min_value = 0.3
	_sens_slider.max_value = 2.5
	_sens_slider.step = 0.05
	_sens_slider.custom_minimum_size = Vector2(160, 0)
	_sens_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sens_slider.value_changed.connect(_on_sens_changed)
	sens_row.add_child(_sens_slider)

	_sens_val_label = Label.new()
	_sens_val_label.custom_minimum_size = Vector2(50, 0)
	sens_row.add_child(_sens_val_label)
	add_child(sens_row)

	# Invert Y: CheckButton
	_invert_btn = CheckButton.new()
	_invert_btn.text = "Invert Y"
	_invert_btn.toggled.connect(_on_invert_toggled)
	add_child(_invert_btn)

	# Master volume: HSlider 0 to 1, showing "%d%%"
	var vol_row := HBoxContainer.new()
	vol_row.add_theme_constant_override("separation", 8)
	var vol_lbl := Label.new()
	vol_lbl.text = "Master volume"
	vol_lbl.custom_minimum_size = Vector2(140, 0)
	vol_row.add_child(vol_lbl)

	_vol_slider = HSlider.new()
	_vol_slider.min_value = 0.0
	_vol_slider.max_value = 1.0
	_vol_slider.step = 0.01
	_vol_slider.custom_minimum_size = Vector2(160, 0)
	_vol_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vol_slider.value_changed.connect(_on_vol_changed)
	vol_row.add_child(_vol_slider)

	_vol_val_label = Label.new()
	_vol_val_label.custom_minimum_size = Vector2(50, 0)
	vol_row.add_child(_vol_val_label)
	add_child(vol_row)

	# Captions: CheckButton
	_captions_btn = CheckButton.new()
	_captions_btn.text = "Captions"
	_captions_btn.toggled.connect(_on_captions_toggled)
	add_child(_captions_btn)

	# High contrast: CheckButton
	_contrast_btn = CheckButton.new()
	_contrast_btn.text = "High contrast"
	_contrast_btn.toggled.connect(_on_contrast_toggled)
	add_child(_contrast_btn)


func _load_values() -> void:
	_updating = true
	var s := get_node_or_null("/root/Settings")
	var sens: float = float(s.get_setting("mouse_sensitivity")) if s != null and s.has_method("get_setting") else 1.0
	var invert: bool = bool(s.get_setting("invert_y")) if s != null and s.has_method("get_setting") else false
	var vol: float = float(s.get_setting("master_volume")) if s != null and s.has_method("get_setting") else 0.8
	var caps: bool = bool(s.get_setting("captions")) if s != null and s.has_method("get_setting") else true
	var hc: bool = bool(s.get_setting("high_contrast")) if s != null and s.has_method("get_setting") else false

	_sens_slider.value = sens
	_sens_val_label.text = "%.2fx" % sens
	_invert_btn.button_pressed = invert
	_vol_slider.value = vol
	_vol_val_label.text = "%d%%" % roundi(vol * 100.0)
	_captions_btn.button_pressed = caps
	_contrast_btn.button_pressed = hc
	_updating = false


func _on_sens_changed(val: float) -> void:
	_sens_val_label.text = "%.2fx" % val
	if not _updating: _save_setting("mouse_sensitivity", val)


func _on_invert_toggled(pressed: bool) -> void:
	if not _updating: _save_setting("invert_y", pressed)


func _on_vol_changed(val: float) -> void:
	_vol_val_label.text = "%d%%" % roundi(val * 100.0)
	if not _updating: _save_setting("master_volume", val)


func _on_captions_toggled(pressed: bool) -> void:
	if not _updating: _save_setting("captions", pressed)


func _on_contrast_toggled(pressed: bool) -> void:
	if not _updating: _save_setting("high_contrast", pressed)


func _save_setting(key: String, value: Variant) -> void:
	var s := get_node_or_null("/root/Settings")
	if s != null and s.has_method("set_setting"):
		s.set_setting(key, value)


func _on_settings_changed(_key: String, _val: Variant) -> void:
	_load_values()
