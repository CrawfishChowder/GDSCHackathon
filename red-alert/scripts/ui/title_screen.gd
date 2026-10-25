extends Control

var _people_label: Label
var _settings_panel: SettingsPanel
var _mission_log_screen: Control
var _credits_screen: Control
var _drone_player: AudioStreamPlayer
var _fade_rect: ColorRect
var _transitioning: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS; set_anchors_preset(PRESET_FULL_RECT)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var mm := get_node_or_null("/root/MalfunctionManager")
	if mm != null: mm.stop_run()
	_build_ui(); _setup_drone(); _update_people()
	var pis := get_node_or_null("/root/PeopleInSpace")
	if pis != null and pis.has_signal("loaded"):
		pis.loaded.connect(func(_cnt: int, _names: Array) -> void: _update_people())

func _build_ui() -> void:
	var tb_script := load("res://scripts/ui/title_background.gd") as GDScript
	var bg: Control = tb_script.new() if tb_script != null else TitleBackground.new()
	add_child(bg)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(PRESET_FULL_RECT); scroll.offset_bottom = -36.0
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var center := CenterContainer.new()
	center.size_flags_horizontal = SIZE_EXPAND_FILL; center.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.add_child(center)

	var panel := PanelContainer.new(); panel.name = "MenuPanel"
	var sb := StyleBoxFlat.new(); sb.bg_color = Color(0.04, 0.05, 0.08, 0.82); sb.set_corner_radius_all(12)
	sb.content_margin_left = 32.0; sb.content_margin_right = 32.0; sb.content_margin_top = 28.0; sb.content_margin_bottom = 28.0
	panel.add_theme_stylebox_override("panel", sb); center.add_child(panel)

	var vbox := VBoxContainer.new(); vbox.name = "MainVBox"
	vbox.custom_minimum_size = Vector2(620, 0); vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12); panel.add_child(vbox)

	var title := Label.new(); title.text = "RED ALERT"; title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 72); title.add_theme_color_override("font_color", Color(1.0, 0.15, 0.15))
	var subtitle := Label.new(); subtitle.text = "Keep the habitat alive for one shift. Every failure is based on a real spaceflight emergency."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 16); subtitle.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	_people_label = Label.new(); _people_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_people_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; _people_label.add_theme_font_size_override("font_size", 14)
	_people_label.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
	var spacer := Control.new(); spacer.custom_minimum_size = Vector2(0, 8)
	for w: Control in [title, subtitle, _people_label, spacer]:
		vbox.add_child(w)

	var btns: Array = [
		["Story shift (best first play)", func() -> void: _start_with_fade("story")],
		["Start shift", func() -> void: _start_with_fade("normal")],
		["Practice (no deaths)", func() -> void: _start_with_fade("practice")],
		["Hard (half the time)", func() -> void: _start_with_fade("hard")],
		["Mission log", _open_mission_log], ["Settings", _toggle_settings],
		["Credits", _open_credits], ["Quit", func() -> void: get_tree().quit()],
	]
	for b: Array in btns:
		_add_btn(vbox, b[0], b[1])

	_settings_panel = SettingsPanel.new(); _settings_panel.visible = false
	vbox.add_child(_settings_panel)

	for sc: Array in [["res://scripts/ui/mission_log_screen.gd", "_mission_log_screen"], ["res://scripts/ui/credits_screen.gd", "_credits_screen"]]:
		var s := load(sc[0]) as GDScript
		if s != null:
			var inst: Control = s.new(); inst.visible = false
			if inst.has_signal("closed"):
				inst.connect("closed", func() -> void: inst.visible = false)
			add_child(inst); set(sc[1], inst)

	var footer := Label.new(); footer.name = "FooterLabel"; footer.text = "Team TBD · LSU Geaux Hack 2026 · Godot 4.7"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; footer.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 14); footer.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
	footer.set_anchors_preset(PRESET_BOTTOM_WIDE); footer.offset_top = -32.0; footer.offset_bottom = -8.0
	footer.mouse_filter = MOUSE_FILTER_IGNORE; add_child(footer)

	_fade_rect = ColorRect.new(); _fade_rect.name = "FadeRect"; _fade_rect.color = Color.BLACK
	_fade_rect.set_anchors_preset(PRESET_FULL_RECT); _fade_rect.mouse_filter = MOUSE_FILTER_IGNORE
	_fade_rect.modulate.a = 0.0; add_child(_fade_rect)

func _setup_drone() -> void:
	var mix_rate := 22050; var samples := int(4.0 * mix_rate); var data := PackedByteArray()
	data.resize(samples * 2); var flen := int(0.02 * mix_rate)
	for i: int in range(samples):
		var t := float(i) / float(mix_rate)
		var val := 0.47 * sin(TAU * 55.0 * t) + 0.47 * sin(TAU * 55.4 * t) + (randf() * 2.0 - 1.0) * 0.05
		var fade := float(i) / float(flen) if i < flen else (float(samples - i) / float(flen) if i > samples - flen else 1.0)
		data.encode_s16(i * 2, int(round(clampf(val * fade, -1.0, 1.0) * 32767.0)))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS; wav.mix_rate = mix_rate; wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD; wav.loop_begin = 0; wav.loop_end = samples; wav.data = data
	_drone_player = AudioStreamPlayer.new()
	_drone_player.name = "AmbientDrone"; _drone_player.stream = wav; _drone_player.volume_db = -18.0
	if AudioServer.get_bus_index("SFX") != -1: _drone_player.bus = "SFX"
	_drone_player.process_mode = PROCESS_MODE_ALWAYS; add_child(_drone_player)
	if DisplayServer.get_name() != "headless": _drone_player.play()

func _add_btn(parent: Control, text: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = text; btn.custom_minimum_size = Vector2(260, 42)
	btn.size_flags_horizontal = SIZE_SHRINK_CENTER; btn.add_theme_font_size_override("font_size", 18)
	btn.pressed.connect(callback); parent.add_child(btn)
	return btn

func _open_mission_log() -> void:
	if _mission_log_screen != null:
		if _mission_log_screen.has_method("refresh"): _mission_log_screen.call("refresh")
		_mission_log_screen.visible = true

func _open_credits() -> void:
	if _credits_screen != null: _credits_screen.visible = true

func _toggle_settings() -> void:
	if _settings_panel != null: _settings_panel.visible = not _settings_panel.visible

func _start_with_fade(mode: String) -> void:
	if _transitioning: return
	_transitioning = true
	if _fade_rect != null:
		_fade_rect.mouse_filter = MOUSE_FILTER_STOP; _fade_rect.modulate.a = 0.0
		var tween := create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(_fade_rect, "modulate:a", 1.0, 0.35)
		tween.tween_callback(func() -> void: _start_shift(mode))
	else:
		_start_shift(mode)

func _start_shift(mode: String) -> void:
	var mm := get_node_or_null("/root/MalfunctionManager")
	if mm != null: mm.set("mode", mode)
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/stage1/stage_1_room.tscn")

func _update_people() -> void:
	if _people_label == null: return
	var pis := get_node_or_null("/root/PeopleInSpace")
	_people_label.text = String(pis.summary_line()) if (pis != null and pis.has_method("summary_line")) else "Live crew data unavailable. More than 600 people have flown in space since 1961."
