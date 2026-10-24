extends CanvasLayer

@onready var prompt_label: Label = $PromptLabel
@onready var game_over: CanvasLayer = get_node_or_null("GameOver")

var alert_label: Label
var stats_label: Label


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	_setup_alert_label()
	_setup_stats_label()


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

	var surv_total := int(mm.survived_seconds)
	var surv_mins := surv_total / 60
	var surv_secs := surv_total % 60
	stats_label.text = "SURVIVED %d:%02d   FIXES %d" % [surv_mins, surv_secs, mm.fixes_count]


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
	stats_label.text = "SURVIVED 0:00   FIXES 0"
	add_child(stats_label)


func _get_mm() -> Node:
	if has_node("/root/MalfunctionManager"):
		return get_node("/root/MalfunctionManager")
	return null
