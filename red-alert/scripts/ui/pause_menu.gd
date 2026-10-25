extends CanvasLayer

var _mode_label: Label
var _settings_panel: SettingsPanel
var _controls_panel: ControlsPanel


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	visible = false
	_build_ui()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		open_menu()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return

	if visible:
		get_viewport().set_input_as_handled()
		_resume()
	elif open_menu():
		get_viewport().set_input_as_handled()


func open_menu() -> bool:
	if is_open_menu():
		return false

	# Ignore if MinigameHost is open
	var mh := get_node_or_null("/root/MinigameHost")
	if mh != null and mh.has_method("is_open") and mh.is_open():
		return false

	# Ignore if a GameOver or ShiftComplete sibling is showing
	var parent_node := get_parent()
	if parent_node != null:
		var go := parent_node.get_node_or_null("GameOver")
		if go != null and go.has_method("is_showing") and go.is_showing():
			return false
		var sc := parent_node.get_node_or_null("ShiftComplete")
		if sc != null and sc.has_method("is_showing") and sc.is_showing():
			return false

	# Ignore if the tree is already paused by something else
	if get_tree() != null and get_tree().paused and not visible:
		return false

	_open()
	return true


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.name = "Backdrop"; bg.color = Color(0.02, 0.03, 0.05, 0.85); bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(460, 320)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.06, 0.08, 0.95); style.set_border_width_all(2); style.border_color = Color(0.3, 0.8, 1.0)
	style.set_corner_radius_all(8)
	style.content_margin_left = 24.0; style.content_margin_top = 20.0
	style.content_margin_right = 24.0; style.content_margin_bottom = 20.0
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.name = "MenuVBox"; vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "PAUSED"; title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32); title.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
	vbox.add_child(title)

	_mode_label = Label.new()
	_mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mode_label.add_theme_font_size_override("font_size", 16); _mode_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(_mode_label)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 6)
	vbox.add_child(spacer)

	_add_btn(vbox, "Resume", _resume)
	_add_btn(vbox, "Settings", _toggle_settings)
	_add_btn(vbox, "Controls", _toggle_controls)
	_add_btn(vbox, "Restart shift", _restart_shift)
	_add_btn(vbox, "Quit to title", _quit_to_title)

	_settings_panel = SettingsPanel.new(); _settings_panel.visible = false
	vbox.add_child(_settings_panel)

	_controls_panel = ControlsPanel.new(); _controls_panel.visible = false
	vbox.add_child(_controls_panel)


func _add_btn(parent: Control, text: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = text; btn.custom_minimum_size = Vector2(220, 38)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_size_override("font_size", 16)
	btn.pressed.connect(callback)
	parent.add_child(btn)
	return btn


func _open() -> void:
	var mm := get_node_or_null("/root/MalfunctionManager")
	var mode_str := "normal"
	if mm != null and "mode" in mm:
		mode_str = String(mm.mode)
	if _mode_label != null:
		_mode_label.text = "Mode: %s" % mode_str
	visible = true
	if get_tree() != null:
		get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func resume() -> void:
	_resume()


func _resume() -> void:
	visible = false
	if _settings_panel != null:
		_settings_panel.visible = false
	if _controls_panel != null:
		_controls_panel.visible = false
	if get_tree() != null:
		get_tree().paused = false
	# Resume mouse look through the player's own capture logic (VNC-safe).
	var player := get_parent().get_parent() if get_parent() != null else null
	if player != null and player.has_method("resume_mouse_look"):
		player.resume_mouse_look()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _toggle_settings() -> void:
	if _settings_panel != null: _settings_panel.visible = not _settings_panel.visible

func _toggle_controls() -> void:
	if _controls_panel != null: _controls_panel.toggle()

func _restart_shift() -> void:
	get_tree().paused = false; get_tree().reload_current_scene()

func _quit_to_title() -> void:
	get_tree().paused = false
	var mm := get_node_or_null("/root/MalfunctionManager")
	if mm != null: mm.stop_run()
	get_tree().change_scene_to_file("res://scenes/ui/title_screen.tscn")

func is_open_menu() -> bool: return visible

func is_showing() -> bool: return visible
