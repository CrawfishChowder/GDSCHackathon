class_name CreditsScreen
extends Control

signal closed

const SECTIONS: Array[Dictionary] = [
	{
		"category": "TEAM",
		"text": "Calvin Gavin · Gerald Lê · Scott Sonnier · Eddie Summitt · Brandon Braswell"
	},
	{
		"category": "SOUND EFFECTS",
		"text": "Sonniss GDC 2015 Game Audio Bundle (sonniss.com): Coll Anderson (Metal Plate, Traditional Sirens) · Detunized (HumBuzz) · Eiravaein Works (Start Select) · Kpow Sounds (UI Soundpacks) · RDGSFX (The Metal Shelf) · SoundMorph (Solar Sky, Users of Tomorrow) · Timothy McHugh (Barefoot on Metal)"
	},
	{
		"category": "VOICES",
		"text": "HAL and Sam voiced with ElevenLabs (sponsor), from lines written by the team"
	},
	{
		"category": "LIVE DATA",
		"text": "NASA DONKI space weather API · Open Notify people-in-space API"
	},
	{
		"category": "HISTORY",
		"text": "incident summaries written by the team from public NASA and historical records"
	},
	{
		"category": "ENGINE",
		"text": "Godot Engine 4.7"
	},
	{
		"category": "AI ASSISTANCE",
		"text": "planning and review by Claude (Anthropic); implementation help by Gemini (Google Antigravity). No AI-generated images or video."
	}
]


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	set_anchors_preset(PRESET_FULL_RECT)
	_build_ui()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE or event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			closed.emit()


func full_text() -> String:
	var lines: PackedStringArray = []
	for sec: Dictionary in SECTIONS:
		lines.append("%s: %s" % [sec["category"], sec["text"]])
	return "\n\n".join(lines)


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0.04, 0.05, 0.07, 1.0)
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.mouse_filter = MOUSE_FILTER_STOP
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(PRESET_FULL_RECT)
	for m in ["margin_left", "margin_right"]: margin.add_theme_constant_override(m, 48)
	for m in ["margin_top", "margin_bottom"]: margin.add_theme_constant_override(m, 32)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	var title := Label.new()
	title.name = "Title"
	title.text = "CREDITS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
	vbox.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var entries_vbox := VBoxContainer.new()
	entries_vbox.name = "EntriesVBox"
	entries_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entries_vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(entries_vbox)

	for sec: Dictionary in SECTIONS:
		_create_section_panel(entries_vbox, str(sec["category"]), str(sec["text"]))

	var back_btn := Button.new()
	back_btn.name = "BackButton"
	back_btn.text = "Back"
	back_btn.custom_minimum_size = Vector2(200, 42)
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_btn.add_theme_font_size_override("font_size", 18)
	back_btn.pressed.connect(func() -> void: closed.emit())
	vbox.add_child(back_btn)


func _create_section_panel(parent: Control, category: String, text: String) -> void:
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

	var cat_lbl := Label.new()
	cat_lbl.text = category
	cat_lbl.add_theme_font_size_override("font_size", 16)
	cat_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	vbox.add_child(cat_lbl)

	var text_lbl := Label.new()
	text_lbl.text = text
	text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_lbl.add_theme_font_size_override("font_size", 14)
	text_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	vbox.add_child(text_lbl)

	parent.add_child(panel)
