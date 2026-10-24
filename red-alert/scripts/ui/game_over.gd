class_name GameOver
extends CanvasLayer

var _cause_label: Label
var _stats_label: Label
var _restart_btn: Button
var _connected: bool = false


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	layer = 20
	visible = false
	_build_ui()
	_connect_malfunction_manager()


func _process(_delta: float) -> void:
	if not _connected:
		_connect_malfunction_manager()


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
	bg.color = Color(0.25, 0.0, 0.0, 0.85)
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
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 18)
	center.add_child(vbox)

	var title := Label.new()
	title.name = "TitleLabel"
	title.text = "YOU DIED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color(1.0, 0.18, 0.18))
	vbox.add_child(title)

	_cause_label = Label.new()
	_cause_label.name = "CauseLabel"
	_cause_label.text = "Cause: Unknown"
	_cause_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cause_label.add_theme_font_size_override("font_size", 22)
	_cause_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	vbox.add_child(_cause_label)

	_stats_label = Label.new()
	_stats_label.name = "StatsLabel"
	_stats_label.text = "Survived 0:00  ·  Fixes 0"
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_label.add_theme_font_size_override("font_size", 18)
	_stats_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	vbox.add_child(_stats_label)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)

	_restart_btn = Button.new()
	_restart_btn.name = "RestartButton"
	_restart_btn.text = "Restart [R]"
	_restart_btn.custom_minimum_size = Vector2(220, 48)
	_restart_btn.add_theme_font_size_override("font_size", 20)
	_restart_btn.process_mode = PROCESS_MODE_ALWAYS
	_restart_btn.pressed.connect(_restart)
	vbox.add_child(_restart_btn)


func _on_player_died(cause_id: String, display_name: String) -> void:
	var final_name := display_name
	if final_name.is_empty():
		var mm := _get_mm()
		if mm != null and mm.has_method("display_name"):
			final_name = mm.display_name(cause_id)
		elif not cause_id.is_empty():
			final_name = cause_id.capitalize()
		else:
			final_name = "Unknown"

	_cause_label.text = "Cause: %s" % final_name

	var surv_mins := 0
	var surv_secs := 0
	var fixes := 0
	var mm := _get_mm()
	if mm != null:
		var surv_total := int(mm.survived_seconds)
		surv_mins = surv_total / 60
		surv_secs = surv_total % 60
		fixes = int(mm.fixes_count)

	_stats_label.text = "Survived %d:%02d  ·  Fixes %d" % [surv_mins, surv_secs, fixes]

	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _connect_malfunction_manager() -> void:
	if _connected:
		return
	var mm := _get_mm()
	if mm != null:
		mm.player_died.connect(_on_player_died)
		_connected = true


func _get_mm() -> Node:
	if has_node("/root/MalfunctionManager"):
		return get_node("/root/MalfunctionManager")
	return null
