class_name MissionLogScreen
extends Control
# MissionLogScreen displays the historical incident log and achievements.
# Opened from the title screen; emits closed when dismissed.

signal closed

var _summary_label: Label
var _entries_vbox: VBoxContainer
var _entry_count_shown: int = 0

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	set_anchors_preset(PRESET_FULL_RECT)
	_build_ui()
	refresh()
	var ml: Node = get_node_or_null("/root/MissionLog")
	if ml != null and ml.has_signal("entry_added"):
		ml.entry_added.connect(func(_entry: Dictionary) -> void: refresh())
	var ach: Node = get_node_or_null("/root/Achievements")
	if ach != null and ach.has_signal("unlocked"):
		ach.unlocked.connect(func(_id: String, _title: String) -> void: refresh())

func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE or event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			closed.emit()

func entry_count_shown() -> int:
	return _entry_count_shown

func refresh() -> void:
	if _summary_label == null or _entries_vbox == null:
		return
	var ml: Node = get_node_or_null("/root/MissionLog")
	var entries_list: Array = ml.entries if (ml != null and "entries" in ml and ml.entries is Array) else []
	var sd: Node = get_node_or_null("/root/SaveData")
	var do_not_press: int = int(sd.get_value("do_not_press_count", 0)) if (sd != null and sd.has_method("get_value")) else 0
	var grade_val: Variant = sd.get_value("best_grade", null) if (sd != null and sd.has_method("get_value")) else null
	var best_grade: String = str(grade_val) if (grade_val != null and str(grade_val) != "") else "--"

	_summary_label.text = "Crew lost: %d   |   DO NOT PRESS presses: %d   |   Best shift grade: %s" % [
		entries_list.size(), do_not_press, best_grade
	]
	for child: Node in _entries_vbox.get_children():
		_entries_vbox.remove_child(child)
		child.queue_free()

	_entry_count_shown = 0
	_build_achievements_section()

	if entries_list.is_empty():
		_add_lbl(_entries_vbox, "No crew lost yet.", 16, Color(0.6, 0.6, 0.6)).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		return

	for i in range(entries_list.size() - 1, -1, -1):
		var item: Variant = entries_list[i]
		if item is Dictionary:
			_create_entry_panel(item)
			_entry_count_shown += 1

func _build_achievements_section() -> void:
	var ach: Node = get_node_or_null("/root/Achievements")
	var all_ids: Array = ach.all_ids() if (ach != null and ach.has_method("all_ids")) else [
		"first_shift", "steady_hands", "by_the_book", "curiosity", "calm", "historian"
	]
	var unlocked_count: int = 0
	for id: Variant in all_ids:
		if ach != null and ach.has_method("is_unlocked") and ach.is_unlocked(id):
			unlocked_count += 1
	var panel := PanelContainer.new()
	panel.name = "AchievementsPanel"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.14, 0.9)
	style.border_color = Color(0.2, 0.3, 0.4, 0.6)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(10.0)
	panel.add_theme_stylebox_override("panel", style)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)
	_add_lbl(vbox, "ACHIEVEMENTS (%d/6)" % unlocked_count, 17, Color(0.3, 0.8, 1.0))
	var list_dict: Dictionary = ach.LIST if (ach != null and "LIST" in ach and ach.LIST is Dictionary) else {}
	for id: Variant in all_ids:
		var sid := str(id)
		var is_unlocked: bool = ach != null and ach.has_method("is_unlocked") and ach.is_unlocked(sid)
		var info: Dictionary = list_dict.get(sid, {})
		var title: String = String(info.get("title", sid))
		var desc: String = String(info.get("desc", ""))
		var mark: String = "✓" if is_unlocked else "○"
		var color := Color(0.2, 0.85, 1.0) if is_unlocked else Color(0.6, 0.6, 0.6)
		_add_lbl(vbox, "%s %s: %s" % [mark, title, desc], 14, color, true)
	_entries_vbox.add_child(panel)

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0.04, 0.05, 0.07, 1.0)
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.mouse_filter = MOUSE_FILTER_STOP
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(PRESET_FULL_RECT)
	for m in ["margin_left", "margin_right"]:
		margin.add_theme_constant_override(m, 48)
	for m in ["margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(m, 32)
	add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)
	_add_lbl(vbox, "MISSION LOG", 36, Color(0.3, 0.8, 1.0)).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_summary_label = _add_lbl(vbox, "", 16, Color(0.85, 0.85, 0.85))
	_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)
	_entries_vbox = VBoxContainer.new()
	_entries_vbox.name = "EntriesVBox"
	_entries_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_entries_vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(_entries_vbox)
	var back_btn := Button.new()
	back_btn.name = "BackButton"
	back_btn.text = "Back"
	back_btn.custom_minimum_size = Vector2(200, 42)
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_btn.add_theme_font_size_override("font_size", 18)
	back_btn.pressed.connect(func() -> void: closed.emit())
	vbox.add_child(back_btn)

func _create_entry_panel(entry: Dictionary) -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.14, 0.9)
	style.border_color = Color(0.2, 0.3, 0.4, 0.6)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(10.0)
	panel.add_theme_stylebox_override("panel", style)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)
	var top_row := HBoxContainer.new()
	top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(top_row)
	var yr := String(entry.get("year", ""))
	var title_str := String(entry.get("title", "Unknown incident"))
	if not yr.is_empty() and not yr in title_str:
		title_str += " (%s)" % yr
	var tl := _add_lbl(top_row, title_str, 17, Color(1.0, 0.85, 0.4))
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var unix_time := int(entry.get("unix_time", 0))
	var date_str := Time.get_datetime_string_from_unix_time(unix_time if unix_time > 0 else int(Time.get_unix_time_from_system()), true)
	_add_lbl(top_row, date_str, 13, Color(0.6, 0.6, 0.6)).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var detail := String(entry.get("detail", ""))
	if not detail.is_empty():
		_add_lbl(vbox, detail, 14, Color(0.9, 0.85, 0.85), true)
	var surv := int(entry.get("survived_seconds", 0.0))
	_add_lbl(vbox, "Survived %d:%02d, fixes %d" % [surv / 60, surv % 60, int(entry.get("fixes", 0))], 13, Color(0.7, 0.7, 0.7))
	_entries_vbox.add_child(panel)

func _add_lbl(parent: Control, text: String, sz: int, col: Color, wrap: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(l)
	return l
