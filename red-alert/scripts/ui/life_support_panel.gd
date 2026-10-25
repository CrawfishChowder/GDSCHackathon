extends Control

const FOOTNOTES: Array[String] = [
	"NASA plans for about 0.82 kg of oxygen per crew member per day.",
	"Each crew member exhales about 1 kg of carbon dioxide per day.",
	"When the scrubbers lose power, carbon dioxide builds up in the cabin.",
	"Apollo 13's crew had to build an improvised CO2 scrubber adapter to survive.",
]

const ROW_DEFS: Array[Dictionary] = [
	{"id": "o2", "title": "O2 RESERVE", "invert": false},
	{"id": "co2", "title": "CO2 SCRUBBED", "invert": true},
	{"id": "power", "title": "POWER", "invert": false},
	{"id": "core_temp", "title": "CORE STABLE", "invert": true},
]

var _rows: Array[Dictionary] = []
var _footnote_label: Label
var _footnote_timer: float = 0.0
var _footnote_index: int = 0
var _blink_timer: float = 0.0


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	mouse_filter = MOUSE_FILTER_IGNORE
	set_anchors_preset(PRESET_TOP_RIGHT)
	offset_left = -276.0
	offset_top = 16.0
	offset_right = -16.0
	offset_bottom = 16.0
	grow_horizontal = GROW_DIRECTION_BEGIN
	grow_vertical = GROW_DIRECTION_END

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(260.0, 0.0)
	panel.mouse_filter = MOUSE_FILTER_IGNORE

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.06, 0.08, 0.95)
	style.set_border_width_all(2)
	style.border_color = Color.CYAN
	style.set_corner_radius_all(6)
	style.content_margin_left = 12.0
	style.content_margin_top = 10.0
	style.content_margin_right = 12.0
	style.content_margin_bottom = 10.0
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var title_label := Label.new()
	title_label.text = "LIFE SUPPORT"
	title_label.mouse_filter = MOUSE_FILTER_IGNORE
	title_label.add_theme_font_size_override("font_size", 14)
	title_label.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	vbox.add_child(title_label)

	for def in ROW_DEFS:
		var row_box := VBoxContainer.new()
		row_box.mouse_filter = MOUSE_FILTER_IGNORE
		row_box.add_theme_constant_override("separation", 2)

		var label_holder := Control.new()
		label_holder.custom_minimum_size = Vector2(0.0, 16.0)
		label_holder.mouse_filter = MOUSE_FILTER_IGNORE

		var row_label := Label.new()
		row_label.set_anchors_preset(PRESET_FULL_RECT)
		row_label.mouse_filter = MOUSE_FILTER_IGNORE
		row_label.add_theme_font_size_override("font_size", 11)
		label_holder.add_child(row_label)
		row_box.add_child(label_holder)

		var bar := ProgressBar.new()
		bar.mouse_filter = MOUSE_FILTER_IGNORE
		bar.max_value = 100.0
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0.0, 10.0)

		var fill_style := StyleBoxFlat.new()
		fill_style.bg_color = Color(0.3, 0.8, 1.0)
		fill_style.set_corner_radius_all(2)
		bar.add_theme_stylebox_override("fill", fill_style)

		var bg_style := StyleBoxFlat.new()
		bg_style.bg_color = Color(0.12, 0.16, 0.2, 0.9)
		bg_style.set_corner_radius_all(2)
		bar.add_theme_stylebox_override("background", bg_style)

		row_box.add_child(bar)
		vbox.add_child(row_box)
		_rows.append({"def": def, "label": row_label, "bar": bar, "fill": fill_style})

	_footnote_label = Label.new()
	_footnote_label.mouse_filter = MOUSE_FILTER_IGNORE
	_footnote_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_footnote_label.add_theme_font_size_override("font_size", 12)
	_footnote_label.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
	_footnote_label.text = FOOTNOTES[0]
	vbox.add_child(_footnote_label)


func _process(delta: float) -> void:
	_blink_timer += delta
	var blink_visible: bool = fposmod(_blink_timer, 1.0) < 0.5

	_footnote_timer += delta
	if _footnote_timer >= 8.0:
		_footnote_timer = fposmod(_footnote_timer, 8.0)
		_footnote_index = (_footnote_index + 1) % FOOTNOTES.size()
		_footnote_label.text = FOOTNOTES[_footnote_index]

	var ls := _get_ls()
	if ls == null:
		return

	for row in _rows:
		var def: Dictionary = row["def"]
		var raw_level: float = float(ls.call("get_level", def["id"]))
		var display_val: float = clampf(((1.0 - raw_level) if def["invert"] else raw_level) * 100.0, 0.0, 100.0)

		var bar: ProgressBar = row["bar"]
		bar.value = display_val

		var fill: StyleBoxFlat = row["fill"]
		var label: Label = row["label"]
		var is_crit: bool = bool(ls.call("is_critical", def["id"]))
		var pct := int(round(display_val))

		if is_crit:
			label.text = "%s  %d%%  CRITICAL" % [def["title"], pct]
			label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.2))
			fill.bg_color = Color(1.0, 0.35, 0.2)
			label.visible = blink_visible
		else:
			label.text = "%s  %d%%" % [def["title"], pct]
			label.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95))
			fill.bg_color = Color(0.3, 0.8, 1.0)
			label.visible = true


func _get_ls() -> Node:
	return get_node_or_null("/root/LifeSupport")
