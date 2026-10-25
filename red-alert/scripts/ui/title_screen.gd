extends Control

var _people_label: Label
var _settings_panel: SettingsPanel
var _mission_log_screen: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(PRESET_FULL_RECT)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_ui()
	_update_people()
	var pis := get_node_or_null("/root/PeopleInSpace")
	if pis != null and pis.has_signal("loaded"):
		pis.loaded.connect(func(_cnt: int, _names: Array) -> void: _update_people())


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0.03, 0.04, 0.06, 1.0)
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(bg)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var center := CenterContainer.new()
	center.size_flags_horizontal = SIZE_EXPAND_FILL
	center.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.name = "MainVBox"
	vbox.custom_minimum_size = Vector2(620, 0)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	center.add_child(vbox)

	var title := Label.new()
	title.text = "RED ALERT"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Color(1.0, 0.15, 0.15))
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Keep the habitat alive for one shift. Every failure is based on a real spaceflight emergency."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	vbox.add_child(subtitle)

	_people_label = Label.new()
	_people_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_people_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_people_label.add_theme_font_size_override("font_size", 14)
	_people_label.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
	vbox.add_child(_people_label)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)

	_add_btn(vbox, "Start shift", func() -> void: _start_shift("normal"))
	_add_btn(vbox, "Practice (no deaths)", func() -> void: _start_shift("practice"))
	_add_btn(vbox, "Hard (half the time)", func() -> void: _start_shift("hard"))
	_add_btn(vbox, "Mission log", _open_mission_log)
	_add_btn(vbox, "Settings", _toggle_settings)
	_add_btn(vbox, "Quit", func() -> void: get_tree().quit())

	_settings_panel = SettingsPanel.new()
	_settings_panel.visible = false
	vbox.add_child(_settings_panel)

	var mls_script := load("res://scripts/ui/mission_log_screen.gd") as GDScript
	if mls_script != null:
		_mission_log_screen = mls_script.new()
		_mission_log_screen.visible = false
		if _mission_log_screen.has_signal("closed"):
			_mission_log_screen.connect("closed", func() -> void: _mission_log_screen.visible = false)
		add_child(_mission_log_screen)


func _add_btn(parent: Control, text: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(260, 42)
	btn.size_flags_horizontal = SIZE_SHRINK_CENTER
	btn.add_theme_font_size_override("font_size", 18)
	btn.pressed.connect(callback)
	parent.add_child(btn)
	return btn


func _open_mission_log() -> void:
	if _mission_log_screen != null:
		if _mission_log_screen.has_method("refresh"):
			_mission_log_screen.call("refresh")
		_mission_log_screen.visible = true


func _toggle_settings() -> void:
	if _settings_panel != null:
		_settings_panel.visible = not _settings_panel.visible


func _start_shift(mode: String) -> void:
	var mm := get_node_or_null("/root/MalfunctionManager")
	if mm != null:
		mm.set("mode", mode)
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/stage1/stage_1_room.tscn")


func _update_people() -> void:
	if _people_label == null:
		return
	var pis := get_node_or_null("/root/PeopleInSpace")
	if pis != null and pis.has_method("summary_line"):
		_people_label.text = String(pis.summary_line())
	else:
		_people_label.text = "Live crew data unavailable. More than 600 people have flown in space since 1961."
