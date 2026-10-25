class_name ControlsPanel
extends PanelContainer

var _labels: Array[Label] = []


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(420, 0)
	if not (get_parent() is Container):
		set_anchors_preset(Control.PRESET_CENTER_RIGHT)
		anchor_left = 1.0; anchor_right = 1.0
		anchor_top = 0.5; anchor_bottom = 0.5
		offset_left = -444.0; offset_right = -24.0
		grow_horizontal = Control.GROW_DIRECTION_BEGIN
		grow_vertical = Control.GROW_DIRECTION_BOTH
	_build_ui()


func _build_ui() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.06, 0.08, 0.95)
	style.set_border_width_all(2)
	style.border_color = Color(0.3, 0.8, 1.0)
	style.set_corner_radius_all(8)
	style.content_margin_left = 18.0; style.content_margin_right = 18.0
	style.content_margin_top = 16.0; style.content_margin_bottom = 16.0
	add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.name = "ContentVBox"
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 6)
	add_child(vbox)

	var header := Label.new()
	header.text = "H to toggle this panel"
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_theme_font_size_override("font_size", 20)
	var bold_font := FontVariation.new()
	bold_font.variation_embolden = 0.8
	header.add_theme_font_override("font", bold_font)
	header.add_theme_color_override("font_color", Color.WHITE)
	_add_entry(vbox, header)

	_add_spacer(vbox, 4)
	_add_heading(vbox, "MOVE")
	_add_text(vbox, "WASD move · Mouse look · Space jump")
	_add_text(vbox, "DualSense: left stick / D-pad move · right stick look · Square jump")

	_add_spacer(vbox, 4)
	_add_heading(vbox, "ACT")
	_add_text(vbox, "E interact / sit / fix")
	_add_text(vbox, "DualSense: Cross / R2 interact · Triangle breathe")
	_add_text(vbox, "In minigames: number keys, Enter, Backspace (shown in [brackets])")

	_add_spacer(vbox, 4)
	_add_heading(vbox, "SURVIVE")
	var red_col := Color(1.0, 0.3, 0.25)
	_add_text(vbox, "HOLD B TO BREATHE when your heart rate climbs", 18, red_col)
	_add_text(vbox, "ONE WRONG MOVE IN A MINIGAME IS FATAL", 18, red_col)
	_add_text(vbox, "FOLLOW >> FIX HERE << AND THE ALARM PING", 18, red_col)

	_add_spacer(vbox, 4)
	_add_heading(vbox, "MENUS")
	_add_text(vbox, "Esc pause / settings · F12 demo keys")
	_add_text(vbox, "DualSense: Options pause · D-pad navigate · Cross select · Circle back")

	_add_spacer(vbox, 6)
	_add_text(vbox, "The HUD can be hidden in Settings.", 13, Color(0.6, 0.6, 0.6))


func _add_heading(parent: Control, text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
	var bold_font := FontVariation.new()
	bold_font.variation_embolden = 0.5
	lbl.add_theme_font_override("font", bold_font)
	_add_entry(parent, lbl)


func _add_text(parent: Control, text: String, font_size: int = 14, color: Color = Color(0.9, 0.9, 0.9)) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	_add_entry(parent, lbl)


func _add_entry(parent: Control, lbl: Label) -> void:
	_labels.append(lbl)
	parent.add_child(lbl)


func _add_spacer(parent: Control, height: int) -> void:
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, height)
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(sp)


func toggle() -> void:
	visible = not visible


func show_panel() -> void:
	visible = true


func hide_panel() -> void:
	visible = false


func is_open() -> bool:
	return visible


func text_content() -> String:
	var texts: PackedStringArray = []
	for lbl in _labels:
		if is_instance_valid(lbl) and not lbl.text.is_empty():
			texts.append(lbl.text)
	return "\n".join(texts)
