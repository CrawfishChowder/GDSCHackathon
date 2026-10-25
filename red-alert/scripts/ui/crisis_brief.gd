class_name CrisisBrief
extends CanvasLayer
# CrisisBrief shows a first-encounter instruction banner for each malfunction.
# Awards first-time grace and explains how to solve the active crisis.

const AMBER_COLOR := Color(1.0, 0.72, 0.1)
const GREY_COLOR := Color(0.7, 0.7, 0.7)
const TEXT_COLOR := Color(0.9, 0.95, 1.0)

const HOW_TO: Dictionary = {
	"reactor": "Center console. Watch the light sequence, then repeat it. Keys 1-4.",
	"o2": "Left console. Type the filter code shown on screen, then Enter.",
	"co2": "Right console. Press the adapter steps in checklist order. Keys 1-4.",
	"power": "Breaker box by the north door. Open the cover, main breaker OFF, then ON.",
	"dust_storm": "East-wall solar array. Keep every system at its minimum, total 90 or less, then Engage.",
}

var _panel: PanelContainer
var _header_label: Label
var _how_to_label: Label
var _grace_label: Label
var _is_showing: bool = false
var _current_text: String = ""
var _tween: Tween = null
var _connected: bool = false
var _seen_local: Dictionary = {}

func _init() -> void:
	name = "CrisisBrief"; layer = 13; process_mode = Node.PROCESS_MODE_ALWAYS

func _ready() -> void:
	layer = 13; process_mode = Node.PROCESS_MODE_ALWAYS; visible = false
	_build_ui(); _connect_manager()

func _process(_delta: float) -> void:
	if not _connected: _connect_manager()

func is_showing() -> bool: return _is_showing and visible
func current_text() -> String: return _current_text if is_showing() else ""

func _build_ui() -> void:
	_panel = PanelContainer.new(); _panel.name = "BriefPanel"; _panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.set_anchors_preset(Control.PRESET_CENTER_TOP); _panel.anchor_left = 0.5; _panel.anchor_right = 0.5
	_panel.offset_left = -280.0; _panel.offset_right = 280.0; _panel.offset_top = 70.0; _panel.offset_bottom = 190.0
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH; _panel.grow_vertical = Control.GROW_DIRECTION_END; _panel.custom_minimum_size = Vector2(560.0, 0.0)
	var style := StyleBoxFlat.new(); style.bg_color = Color(0.04, 0.06, 0.08, 0.95); style.set_border_width_all(2); style.border_color = AMBER_COLOR; style.set_corner_radius_all(6); style.set_content_margin_all(12.0)
	_panel.add_theme_stylebox_override("panel", style)
	var vbox := VBoxContainer.new(); vbox.name = "VBox"; vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE; vbox.add_theme_constant_override("separation", 6); _panel.add_child(vbox)
	_header_label = _make_label(vbox, "HeaderLabel", 24, AMBER_COLOR, false)
	_how_to_label = _make_label(vbox, "HowToLabel", 16, TEXT_COLOR, true)
	_grace_label = _make_label(vbox, "GraceLabel", 14, GREY_COLOR, false); _grace_label.text = "+15 s first-time grace"
	add_child(_panel)

func _make_label(p: Control, n: String, sz: int, col: Color, wrap: bool) -> Label:
	var l := Label.new(); l.name = n; l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", sz); l.add_theme_color_override("font_color", col)
	l.add_theme_constant_override("outline_size", 4); l.add_theme_color_override("font_outline_color", Color.BLACK)
	if wrap: l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p.add_child(l); return l

func _connect_manager() -> void:
	if _connected: return
	var mm: Node = get_node_or_null("/root/MalfunctionManager")
	if mm != null and mm.has_signal("malfunction_started"):
		if not mm.malfunction_started.is_connected(_on_malfunction_started): mm.malfunction_started.connect(_on_malfunction_started)
		if mm.has_signal("malfunction_fixed") and not mm.malfunction_fixed.is_connected(_on_malfunction_fixed): mm.malfunction_fixed.connect(_on_malfunction_fixed)
		if mm.has_signal("player_died") and not mm.player_died.is_connected(_on_player_died): mm.player_died.connect(_on_player_died)
		if mm.has_signal("run_started") and not mm.run_started.is_connected(_on_run_started): mm.run_started.connect(_on_run_started)
		if mm.has_signal("shift_completed") and not mm.shift_completed.is_connected(_on_shift_completed): mm.shift_completed.connect(_on_shift_completed)
		_connected = true

func _on_malfunction_started(id: String, display_name: String = "", _time_limit: float = 0.0) -> void:
	var mm: Node = get_node_or_null("/root/MalfunctionManager")
	if mm != null and bool(mm.get("countdown_frozen")): return
	var sd: Node = get_node_or_null("/root/SaveData")
	var key := "seen_" + id
	var seen: bool = bool(sd.get_value(key, false)) if (sd != null and sd.has_method("get_value")) else _seen_local.get(key, false)
	if seen: return
	if sd != null and sd.has_method("set_value"): sd.set_value(key, true)
	_seen_local[key] = true
	if mm != null: mm.time_left += 15.0
	_show_brief(id, display_name)

func _show_brief(id: String, display_name: String) -> void:
	var dname := display_name
	if dname.is_empty():
		var mm: Node = get_node_or_null("/root/MalfunctionManager")
		if mm != null and mm.has_method("display_name"): dname = String(mm.display_name(id))
	if dname.is_empty():
		match id:
			"reactor": dname = "Reactor meltdown"
			"power": dname = "Power failure"
			"o2": dname = "O2 depletion"
			"co2": dname = "CO2 buildup"
			"dust_storm": dname = "Dust storm"
			_: dname = id.capitalize()
	var how_to: String = String(HOW_TO.get(id, ""))
	var header := "NEW CRISIS: " + dname.to_upper()
	_header_label.text = header; _how_to_label.text = how_to; _grace_label.text = "+15 s first-time grace"
	_current_text = "%s\n%s\n%s" % [header, how_to, _grace_label.text]
	if _tween != null and _tween.is_valid(): _tween.kill()
	_is_showing = true; visible = true; _panel.visible = true; _panel.modulate.a = 1.0
	_tween = create_tween()
	if _tween != null:
		_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS); _tween.tween_interval(8.0)
		_tween.tween_property(_panel, "modulate:a", 0.0, 0.3); _tween.tween_callback(_hide_brief)

func _hide_brief() -> void:
	if _tween != null and _tween.is_valid(): _tween.kill()
	_is_showing = false; visible = false; _current_text = ""

func _on_malfunction_fixed(_id: String) -> void: _hide_brief()
func _on_player_died(_c: String, _d: String) -> void: _hide_brief()
func _on_run_started() -> void: _hide_brief()
func _on_shift_completed() -> void: _hide_brief()
