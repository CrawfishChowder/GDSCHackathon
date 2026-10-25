extends Node

signal unlocked(id: String, title: String)

const LIST := {
	"first_shift": {"title": "First Shift", "desc": "Survive a full shift."},
	"steady_hands": {"title": "Steady Hands", "desc": "Survive a shift without your heart rate passing 120."},
	"by_the_book": {"title": "By the Book", "desc": "Survive a shift on Hard."},
	"curiosity": {"title": "Curiosity", "desc": "Press the button you were told not to press."},
	"calm": {"title": "Calm Under Pressure", "desc": "Hold your breath steady (B) for 10 seconds in one shift."},
	"historian": {"title": "Historian", "desc": "Learn every incident in the mission log."},
}

var _unlocked_ids: Array[String] = []; var _max_bpm: float = 72.0; var _breathing_seconds: float = 0.0
var _canvas_layer: CanvasLayer; var _toast_panel: PanelContainer; var _toast_title: Label; var _toast_desc: Label
var _toast_queue: Array[Dictionary] = []; var _showing_toast: bool = false

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	var sd := _get_save_data()
	if sd != null and sd.has_method("get_value"):
		var raw: Variant = sd.get_value("achievements", [])
		if raw is Array:
			for item: Variant in raw:
				if item is String and not _unlocked_ids.has(item): _unlocked_ids.append(item)
	_build_toast_ui(); _connect_signals(); _check_historian()

func _process(delta: float) -> void:
	_connect_signals()
	var mm := _get_mm()
	if mm != null and mm.running:
		var stress := _get_stress()
		if stress != null:
			if stress.heart_rate > _max_bpm: _max_bpm = stress.heart_rate
			if stress.has_method("is_breathing") and stress.is_breathing():
				_breathing_seconds += delta
				if _breathing_seconds >= 10.0: unlock("calm")

func _connect_signals() -> void:
	var mm := _get_mm(); var ml := _get_mission_log()
	if mm != null:
		if mm.has_signal("run_started") and not mm.run_started.is_connected(_on_run_started): mm.run_started.connect(_on_run_started)
		if mm.has_signal("shift_completed") and not mm.shift_completed.is_connected(_on_shift_completed): mm.shift_completed.connect(_on_shift_completed)
		if mm.has_signal("player_died") and not mm.player_died.is_connected(_on_player_died): mm.player_died.connect(_on_player_died)
	if ml != null and ml.has_signal("entry_added") and not ml.entry_added.is_connected(_on_entry_added): ml.entry_added.connect(_on_entry_added)

func _on_run_started() -> void:
	var stress := _get_stress()
	_max_bpm = float(stress.heart_rate) if stress != null else 72.0; _breathing_seconds = 0.0

func _on_shift_completed() -> void:
	unlock("first_shift")
	if _max_bpm <= 120.0: unlock("steady_hands")
	var mm := _get_mm()
	if mm != null and str(mm.mode) == "hard": unlock("by_the_book")

func _on_player_died(cause_id: String, _display_name: String) -> void:
	var mm := _get_mm()
	if (mm != null and mm.death_kind == "button") or cause_id == "do_not_press": unlock("curiosity")
	_check_historian()

func _on_entry_added(_entry: Dictionary) -> void:
	_check_historian()

func _check_historian() -> void:
	if is_unlocked("historian"): return
	var ml := _get_mission_log()
	if ml == null: return
	var incidents: Dictionary = ml.INCIDENTS if "INCIDENTS" in ml else {}
	if incidents.is_empty(): return
	var covered := {}; var entries_list: Array = ml.entries if "entries" in ml else []
	for entry: Variant in entries_list:
		if entry is Dictionary and entry.has("cause_id"): covered[str(entry["cause_id"])] = true
	for key: Variant in incidents.keys():
		if not covered.has(str(key)): return
	unlock("historian")

func unlock(id: Variant) -> void:
	var sid := str(id)
	if not LIST.has(sid) or is_unlocked(sid): return
	var sd := _get_save_data(); var arr: Array = []
	if sd != null and sd.has_method("get_value"):
		var raw: Variant = sd.get_value("achievements", [])
		if raw is Array: arr = raw.duplicate()
	if not arr.has(sid): arr.append(sid)
	if sd != null and sd.has_method("set_value"): sd.set_value("achievements", arr)
	if not _unlocked_ids.has(sid): _unlocked_ids.append(sid)
	var title: String = String(LIST[sid].get("title", "")); var desc: String = String(LIST[sid].get("desc", ""))
	unlocked.emit(sid, title); _queue_toast(title, desc)

func is_unlocked(id: Variant) -> bool:
	var sid := str(id); var sd := _get_save_data()
	if sd != null and sd.has_method("get_value"):
		var raw: Variant = sd.get_value("achievements", null)
		if raw is Array: return raw.has(sid)
	return _unlocked_ids.has(sid)

func all_ids() -> Array:
	return LIST.keys()

func _build_toast_ui() -> void:
	_canvas_layer = CanvasLayer.new(); _canvas_layer.layer = 26; _canvas_layer.process_mode = PROCESS_MODE_ALWAYS; add_child(_canvas_layer)
	_toast_panel = PanelContainer.new(); _toast_panel.name = "ToastPanel"; _toast_panel.process_mode = PROCESS_MODE_ALWAYS
	_toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE; _toast_panel.visible = false
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.12, 0.95); style.border_color = Color(0.2, 0.8, 0.9, 0.9)
	style.set_border_width_all(1); style.set_corner_radius_all(6); style.set_content_margin_all(12.0)
	_toast_panel.add_theme_stylebox_override("panel", style)
	_toast_panel.anchors_preset = Control.PRESET_BOTTOM_RIGHT; _toast_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN; _toast_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_toast_panel.offset_left = 20.0; _toast_panel.offset_right = 360.0; _toast_panel.offset_top = -120.0; _toast_panel.offset_bottom = -20.0
	_toast_panel.custom_minimum_size = Vector2(340, 80)
	var vbox := VBoxContainer.new(); vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE; vbox.add_theme_constant_override("separation", 2); _toast_panel.add_child(vbox)
	var hdr := Label.new(); hdr.text = "ACHIEVEMENT UNLOCKED"; hdr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hdr.add_theme_font_size_override("font_size", 13); hdr.add_theme_color_override("font_color", Color(0.2, 0.85, 1.0)); vbox.add_child(hdr)
	_toast_title = Label.new(); _toast_title.mouse_filter = Control.MOUSE_FILTER_IGNORE; _toast_title.add_theme_font_size_override("font_size", 20); _toast_title.add_theme_color_override("font_color", Color.WHITE); vbox.add_child(_toast_title)
	_toast_desc = Label.new(); _toast_desc.mouse_filter = Control.MOUSE_FILTER_IGNORE; _toast_desc.add_theme_font_size_override("font_size", 14); _toast_desc.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	_toast_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; vbox.add_child(_toast_desc)
	_canvas_layer.add_child(_toast_panel)

func _queue_toast(title: String, desc: String) -> void:
	_toast_queue.append({"title": title, "desc": desc})
	if not _showing_toast: _show_next_toast()

func _show_next_toast() -> void:
	if _toast_queue.is_empty():
		_showing_toast = false
		if _toast_panel != null: _toast_panel.visible = false
		return
	_showing_toast = true
	var item: Dictionary = _toast_queue.pop_front()
	if _toast_title != null: _toast_title.text = String(item.get("title", ""))
	if _toast_desc != null: _toast_desc.text = String(item.get("desc", ""))
	if _toast_panel == null: _show_next_toast(); return
	_toast_panel.offset_left = 20.0; _toast_panel.offset_right = 360.0; _toast_panel.visible = true
	var tween := create_tween()
	if tween == null: _showing_toast = false; return
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_toast_panel, "offset_left", -360.0, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_toast_panel, "offset_right", -20.0, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_interval(3.0)
	tween.tween_property(_toast_panel, "offset_left", 20.0, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(_toast_panel, "offset_right", 360.0, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_callback(_show_next_toast)

func _get_save_data() -> Node: return get_node_or_null("/root/SaveData")
func _get_mm() -> Node: return get_node_or_null("/root/MalfunctionManager")
func _get_stress() -> Node: return get_node_or_null("/root/Stress")
func _get_mission_log() -> Node: return get_node_or_null("/root/MissionLog")
