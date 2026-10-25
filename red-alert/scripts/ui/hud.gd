extends CanvasLayer

@onready var prompt_label: Label = $PromptLabel
@onready var game_over: CanvasLayer = get_node_or_null("GameOver")

var alert_label: Label
var stats_label: Label


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	_setup_alert_label()
	_setup_stats_label()
	_apply_high_contrast()
	var s := get_node_or_null("/root/Settings")
	if s != null and s.has_signal("settings_changed"):
		s.settings_changed.connect(_on_settings_changed)


func _process(_delta: float) -> void:
	var mm := _get_mm()
	if mm == null:
		if alert_label != null:
			alert_label.visible = false
		return

	var active_id: String = mm.active_id
	if active_id != "":
		var dname: String = ""
		if mm.has_method("display_name"):
			dname = mm.display_name(active_id)
		elif mm.get("MALFUNCTIONS") and mm.MALFUNCTIONS.has(active_id):
			dname = mm.MALFUNCTIONS[active_id].get("name", active_id)
		else:
			dname = active_id

		var time_left: float = mm.time_left
		var total_secs := int(ceil(maxf(0.0, time_left)))
		var mins := total_secs / 60
		var secs := total_secs % 60
		alert_label.text = "!! %s  %d:%02d !!" % [dname.to_upper(), mins, secs]

		if time_left < 10.0:
			alert_label.visible = fposmod(time_left, 1.0) >= 0.5
		else:
			alert_label.visible = true
	else:
		alert_label.visible = false

	var shift_total := int(ceil(maxf(0.0, mm.shift_time_left())))
	var shift_mins := shift_total / 60
	var shift_secs := shift_total % 60
	stats_label.text = "SHIFT %d:%02d LEFT   FIXES %d" % [shift_mins, shift_secs, mm.fixes_count]


func set_prompt(text: String) -> void:
	if text.is_empty():
		prompt_label.visible = false
		prompt_label.text = ""
	else:
		prompt_label.text = "[E] " + text
		prompt_label.visible = true


func _setup_alert_label() -> void:
	alert_label = Label.new()
	alert_label.name = "AlertLabel"
	alert_label.anchors_preset = Control.PRESET_CENTER_TOP
	alert_label.anchor_left = 0.5
	alert_label.anchor_right = 0.5
	alert_label.anchor_top = 0.0
	alert_label.anchor_bottom = 0.0
	alert_label.offset_left = -400.0
	alert_label.offset_top = 24.0
	alert_label.offset_right = 400.0
	alert_label.offset_bottom = 68.0
	alert_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	alert_label.grow_vertical = Control.GROW_DIRECTION_END
	alert_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	alert_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	alert_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	alert_label.add_theme_font_size_override("font_size", 30)
	alert_label.add_theme_color_override("font_color", Color(1.0, 0.15, 0.15))
	alert_label.visible = false
	add_child(alert_label)


func _setup_stats_label() -> void:
	stats_label = Label.new()
	stats_label.name = "StatsLabel"
	stats_label.anchors_preset = Control.PRESET_TOP_LEFT
	stats_label.offset_left = 16.0
	stats_label.offset_top = 16.0
	stats_label.offset_right = 350.0
	stats_label.offset_bottom = 40.0
	stats_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats_label.add_theme_font_size_override("font_size", 16)
	stats_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	stats_label.text = "SHIFT 5:00 LEFT   FIXES 0"
	add_child(stats_label)


func _apply_high_contrast() -> void:
	var s := get_node_or_null("/root/Settings")
	var hc: bool = bool(s.get_setting("high_contrast")) if s != null and s.has_method("get_setting") else false
	var alert_sz := 38 if hc else 30
	var stats_sz := 20 if hc else 16
	var outline := 8 if hc else 0
	if alert_label != null:
		alert_label.add_theme_font_size_override("font_size", alert_sz)
		alert_label.add_theme_constant_override("outline_size", outline)
		alert_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	if stats_label != null:
		stats_label.add_theme_font_size_override("font_size", stats_sz)
		stats_label.add_theme_constant_override("outline_size", outline)
		stats_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))


func _on_settings_changed(key: String, _val: Variant) -> void:
	if key == "high_contrast":
		_apply_high_contrast()


func _get_mm() -> Node:
	if has_node("/root/MalfunctionManager"):
		return get_node("/root/MalfunctionManager")
	return null
