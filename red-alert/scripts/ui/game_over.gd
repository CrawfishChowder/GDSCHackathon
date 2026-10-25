class_name GameOver
extends CanvasLayer

var _stats_label: Label
var _people_label: Label
var _detail_label: Label
var _incident_title_label: Label
var _summary_label: Label
var _lesson_label: Label
var _crew_lost_label: Label
var _restart_btn: Button
var _connected: bool = false


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	layer = 20
	visible = false
	_build_ui()
	_connect_mission_log()


func _process(_delta: float) -> void:
	if not _connected:
		_connect_mission_log()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_R or event.keycode == KEY_R:
			get_viewport().set_input_as_handled()
			_restart()


func is_showing() -> bool:
	return visible


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0.12, 0.02, 0.02, 0.92)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.custom_minimum_size = Vector2(700, 0)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	center.add_child(vbox)

	_add_label(vbox, "YOU DIED", 44, Color(1.0, 0.18, 0.18))
	_detail_label = _add_label(vbox, "", 18, Color(1.0, 0.85, 0.85), true)
	_stats_label = _add_label(vbox, "Survived 0:00  ·  Fixes 0", 16, Color(0.75, 0.75, 0.75))
	_people_label = _add_label(vbox, "", 16, Color(0.75, 0.75, 0.75), true)
	_add_label(vbox, "MISSION LOG", 18, Color(0.3, 0.8, 1.0))
	_incident_title_label = _add_label(vbox, "", 20, Color(1.0, 0.9, 0.4))
	_summary_label = _add_label(vbox, "", 14, Color(0.9, 0.9, 0.9), true)
	_lesson_label = _add_label(vbox, "", 14, Color(0.65, 0.65, 0.65), true)
	_crew_lost_label = _add_label(vbox, "", 15, Color(0.85, 0.45, 0.45))

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 6)
	vbox.add_child(spacer)

	_restart_btn = Button.new()
	_restart_btn.name = "RestartButton"
	_restart_btn.text = "Restart [R]"
	_restart_btn.custom_minimum_size = Vector2(200, 42)
	_restart_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_restart_btn.add_theme_font_size_override("font_size", 18)
	_restart_btn.process_mode = PROCESS_MODE_ALWAYS
	_restart_btn.pressed.connect(_restart)
	vbox.add_child(_restart_btn)


func _add_label(parent: Control, text: String, size: int, color: Color, wrap: bool = false) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	if wrap:
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.custom_minimum_size = Vector2(700, 0)
	parent.add_child(lbl)
	return lbl


func _on_entry_added(entry: Dictionary) -> void:
	var detail := String(entry.get("detail", ""))
	_detail_label.text = detail
	_detail_label.visible = not detail.is_empty()

	var surv := int(entry.get("survived_seconds", 0.0))
	_stats_label.text = "Survived %d:%02d  ·  Fixes %d" % [surv / 60, surv % 60, int(entry.get("fixes", 0))]

	var pis: Node = get_node_or_null("/root/PeopleInSpace")
	if pis != null:
		_people_label.text = pis.summary_line()

	var yr := String(entry.get("year", ""))
	var title_str := String(entry.get("title", "")) + (" (%s)" % yr if not yr.is_empty() else "")
	_incident_title_label.text = title_str
	_incident_title_label.visible = not title_str.is_empty()

	_summary_label.text = String(entry.get("summary", ""))
	_summary_label.visible = not _summary_label.text.is_empty()
	_lesson_label.text = String(entry.get("lesson", ""))
	_lesson_label.visible = not _lesson_label.text.is_empty()

	var ml := _get_mission_log()
	var count := (ml.entries as Array).size() if ml != null and "entries" in ml else 1
	_crew_lost_label.text = "Crew lost on this station: %d" % count

	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _connect_mission_log() -> void:
	if _connected:
		return
	var ml := _get_mission_log()
	if ml != null and ml.has_signal("entry_added"):
		ml.entry_added.connect(_on_entry_added)
		_connected = true


func _get_mission_log() -> Node:
	if has_node("/root/MissionLog"):
		return get_node("/root/MissionLog")
	return null
