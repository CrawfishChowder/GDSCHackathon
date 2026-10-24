class_name ShiftComplete
extends CanvasLayer

const COMPARISONS := [
	"Scott Kelly: 340 consecutive days aboard the International Space Station (2015–2016).",
	"Valeri Polyakov: about 437 days aboard Mir (1994–1995), the longest single spaceflight.",
	"Apollo 13: after an oxygen tank exploded (1970), the crew survived nearly four days in a crippled spacecraft and made it home.",
]

var _summary_label: Label
var _o2_label: Label
var _lost_label: Label
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
	bg.color = Color(0.0, 0.08, 0.12, 0.92)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.custom_minimum_size = Vector2(760.0, 0.0)
	vbox.add_theme_constant_override("separation", 10)
	center.add_child(vbox)

	vbox.add_child(_create_label("SHIFT COMPLETE", 52, Color.CYAN))
	_summary_label = _create_label("You kept the habitat alive for 0:00 and fixed 0 failures.", 20, Color(0.9, 0.9, 0.9))
	vbox.add_child(_summary_label)

	_o2_label = _create_label("You breathed about 0.0 g of oxygen. NASA plans for about 0.82 kg per crew member per day.", 16, Color(0.75, 0.85, 0.9))
	vbox.add_child(_o2_label)

	vbox.add_child(_create_label("HOW REAL CREWS COMPARE", 22, Color(0.6, 0.9, 1.0)))
	for fact in COMPARISONS:
		vbox.add_child(_create_label(fact, 15, Color(0.8, 0.8, 0.8)))

	_lost_label = _create_label("Crew lost on this station before you: 0", 16, Color(0.7, 0.7, 0.7))
	vbox.add_child(_lost_label)

	_restart_btn = Button.new()
	_restart_btn.text = "New shift [R]"
	_restart_btn.custom_minimum_size = Vector2(220.0, 48.0)
	_restart_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_restart_btn.add_theme_font_size_override("font_size", 20)
	_restart_btn.process_mode = PROCESS_MODE_ALWAYS
	_restart_btn.pressed.connect(_restart)
	vbox.add_child(_restart_btn)


func _create_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(760.0, 0.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _on_shift_completed() -> void:
	_update_stats()
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _update_stats() -> void:
	var surv_secs_float := 0.0
	var fixes := 0
	var mm := _get_mm()
	if mm != null:
		surv_secs_float = float(mm.survived_seconds)
		fixes = int(mm.fixes_count)

	var surv_total := int(surv_secs_float)
	var surv_mins := surv_total / 60
	var surv_secs := surv_total % 60
	_summary_label.text = "You kept the habitat alive for %d:%02d and fixed %d failures." % [surv_mins, surv_secs, fixes]

	var grams: float = 820.0 * surv_secs_float / 86400.0
	_o2_label.text = "You breathed about %.1f g of oxygen. NASA plans for about 0.82 kg per crew member per day." % grams

	var lost_count := 0
	var mlog := _get_mission_log()
	if mlog != null and "entries" in mlog:
		lost_count = (mlog.get("entries") as Array).size()
	_lost_label.text = "Crew lost on this station before you: %d" % lost_count


func _restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _connect_malfunction_manager() -> void:
	if _connected:
		return
	var mm := _get_mm()
	if mm != null:
		mm.shift_completed.connect(_on_shift_completed)
		_connected = true


func _get_mm() -> Node:
	return get_node_or_null("/root/MalfunctionManager")


func _get_mission_log() -> Node:
	return get_node_or_null("/root/MissionLog")
