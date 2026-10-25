class_name TitleScreen
extends Control
# TitleScreen handles main menu display, shift mode selection, and sub-screen navigation.
# Listens to PeopleInSpace for crew telemetry and launches Stage 1 with a fade transition.

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
	var mm: Node = get_node_or_null("/root/MalfunctionManager")
	if mm != null and mm.has_method("stop_run"):
		mm.stop_run()
	_build_ui(); _setup_drone(); _update_people()
	var pis: Node = get_node_or_null("/root/PeopleInSpace")
	if pis != null and pis.has_signal("loaded"):
		pis.connect("loaded", func(_c: int, _n: Array) -> void: _update_people())
	ControllerSupport.focus_buttons(self, true)

func _build_ui() -> void:
	var tb := load("res://scripts/ui/title_background.gd") as GDScript
	add_child(tb.new() if tb != null else TitleBackground.new())
	var scroll := ScrollContainer.new(); scroll.set_anchors_preset(PRESET_FULL_RECT); scroll.offset_bottom = -36.0
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; add_child(scroll)
	var center := CenterContainer.new(); center.size_flags_horizontal = SIZE_EXPAND_FILL; center.size_flags_vertical = SIZE_EXPAND_FILL; scroll.add_child(center)
	var panel := PanelContainer.new(); panel.name = "MenuPanel"
	var sb := StyleBoxFlat.new(); sb.bg_color = Color(0.04, 0.05, 0.08, 0.82); sb.set_corner_radius_all(12); sb.set_content_margin_all(28.0)
	panel.add_theme_stylebox_override("panel", sb); center.add_child(panel)
	var vbox := VBoxContainer.new(); vbox.name = "MainVBox"; vbox.custom_minimum_size = Vector2(620, 0)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER; vbox.add_theme_constant_override("separation", 12); panel.add_child(vbox)

	for item in [["RED ALERT", 72, Color(1, 0.15, 0.15)], ["Keep the habitat alive for one shift. Every failure is based on a real spaceflight emergency.", 16, Color(0.85, 0.85, 0.85)]]:
		var l := Label.new(); l.text = item[0]; l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", item[1]); l.add_theme_color_override("font_color", item[2]); l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; vbox.add_child(l)

	_people_label = Label.new(); _people_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_people_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; _people_label.add_theme_font_size_override("font_size", 14); _people_label.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65)); vbox.add_child(_people_label)

	var btns: Array = [
		["Story shift (best first play)", func() -> void: _start_with_fade("story")],
		["Start shift", func() -> void: _start_with_fade("normal")],
		["Practice (no deaths)", func() -> void: _start_with_fade("practice")],
		["Hard (half the time)", func() -> void: _start_with_fade("hard")],
		["Mission log", func() -> void: _open_screen(_mission_log_screen)],
		["Settings", _toggle_settings],
		["Credits", func() -> void: _open_screen(_credits_screen)],
		["Quit", _quit_game],
	]
	for b in btns:
		var btn := Button.new(); btn.text = b[0]; btn.custom_minimum_size = Vector2(260, 42); btn.size_flags_horizontal = SIZE_SHRINK_CENTER; btn.add_theme_font_size_override("font_size", 18); btn.pressed.connect(b[1]); vbox.add_child(btn)

	_settings_panel = SettingsPanel.new(); _settings_panel.visible = false; vbox.add_child(_settings_panel)
	for sc in [["res://scripts/ui/mission_log_screen.gd", "_mission_log_screen"], ["res://scripts/ui/credits_screen.gd", "_credits_screen"]]:
		var s := load(sc[0]) as GDScript
		if s != null:
			var inst: Control = s.new()
			inst.visible = false
			inst.connect("closed", func() -> void:
				inst.visible = false
				ControllerSupport.focus_buttons(self, true)
			)
			add_child(inst)
			set(sc[1], inst)

	var footer := Label.new(); footer.name = "FooterLabel"; footer.text = "Team TBD · LSU Geaux Hack 2026 · Godot 4.7"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; footer.add_theme_font_size_override("font_size", 14); footer.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
	footer.set_anchors_preset(PRESET_BOTTOM_WIDE); footer.offset_top = -32.0; footer.offset_bottom = -8.0; footer.mouse_filter = MOUSE_FILTER_IGNORE; add_child(footer)

	_fade_rect = ColorRect.new(); _fade_rect.name = "FadeRect"; _fade_rect.color = Color.BLACK; _fade_rect.set_anchors_preset(PRESET_FULL_RECT); _fade_rect.mouse_filter = MOUSE_FILTER_IGNORE; _fade_rect.modulate.a = 0.0; add_child(_fade_rect)

# Procedural two-tone ambient sound generator for the title menu.
func _setup_drone() -> void:
	var mix_rate := 22050; var samples := int(4.0 * mix_rate); var data := PackedByteArray(); data.resize(samples * 2)
	for i in range(samples):
		var t := float(i) / float(mix_rate); var val := 0.47 * sin(TAU * 55.0 * t) + 0.47 * sin(TAU * 55.4 * t)
		data.encode_s16(i * 2, int(round(clampf(val, -1.0, 1.0) * 32767.0)))
	var wav := AudioStreamWAV.new(); wav.format = AudioStreamWAV.FORMAT_16_BITS; wav.mix_rate = mix_rate; wav.loop_mode = AudioStreamWAV.LOOP_FORWARD; wav.loop_end = samples; wav.data = data
	_drone_player = AudioStreamPlayer.new(); _drone_player.name = "AmbientDrone"; _drone_player.stream = wav; _drone_player.volume_db = -18.0
	if AudioServer.get_bus_index("SFX") != -1: _drone_player.bus = "SFX"
	add_child(_drone_player)
	if DisplayServer.get_name() != "headless": _drone_player.play()

func _toggle_settings() -> void:
	if _settings_panel == null:
		return
	_settings_panel.visible = not _settings_panel.visible
	if _settings_panel.visible:
		ControllerSupport.focus_buttons(_settings_panel, true)

func _open_screen(scr: Control) -> void:
	if scr != null:
		if scr.has_method("refresh"): scr.call("refresh")
		scr.visible = true
		ControllerSupport.focus_buttons(scr, true)

func _quit_game() -> void:
	if _transitioning:
		return
	_transitioning = true
	if get_tree() != null:
		get_tree().paused = false
		get_tree().quit()

# Fades the screen to black before loading Stage 1.
func _start_with_fade(mode: String) -> void:
	if _transitioning:
		return
	_transitioning = true
	if _fade_rect != null:
		_fade_rect.mouse_filter = MOUSE_FILTER_STOP; _fade_rect.modulate.a = 0.0
		var tween := create_tween()
		if tween != null:
			tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS); tween.tween_property(_fade_rect, "modulate:a", 1.0, 0.35)
			tween.tween_callback(func() -> void: _start_shift(mode))
	else:
		_start_shift(mode)

func _start_shift(mode: String) -> void:
	var mm: Node = get_node_or_null("/root/MalfunctionManager")
	if mm != null:
		mm.set("mode", mode)
	if get_tree() != null:
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/stage1/stage_1_room.tscn")

func _update_people() -> void:
	if _people_label == null:
		return
	var pis: Node = get_node_or_null("/root/PeopleInSpace")
	if pis != null and pis.has_method("summary_line"):
		_people_label.text = String(pis.summary_line())
	else:
		_people_label.text = "Live crew data unavailable. More than 600 people have flown in space since 1961."
