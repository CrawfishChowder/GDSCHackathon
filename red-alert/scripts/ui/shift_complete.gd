class_name ShiftComplete
extends CanvasLayer

const COMPARISONS := [
	"Scott Kelly: 340 consecutive days aboard the International Space Station (2015–2016).",
	"Valeri Polyakov: about 437 days aboard Mir (1994–1995), the longest single spaceflight.",
	"Apollo 13: after an oxygen tank exploded (1970), the crew survived nearly four days in a crippled spacecraft and made it home.",
]

var _summary_label: Label
var _o2_label: Label
var _people_label: Label
var _grade_label: Label
var _new_best_label: Label
var _notes_label: Label
var _lost_label: Label
var _restart_btn: Button
var _flash_rect: ColorRect
var _connected: bool = false

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS; layer = 20; visible = false
	_build_ui(); _connect_malfunction_manager()

func _process(_delta: float) -> void:
	if not _connected: _connect_malfunction_manager()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_R or event.keycode == KEY_R:
			get_viewport().set_input_as_handled()
			_restart()

func is_showing() -> bool: return visible

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
	_create_label(vbox, "SHIFT COMPLETE", 52, Color.CYAN)
	_summary_label = _create_label(vbox, "You kept the habitat alive for 0:00 and fixed 0 failures.", 20, Color(0.9, 0.9, 0.9))
	_o2_label = _create_label(vbox, "You breathed about 0.0 g of oxygen. NASA plans for about 0.84 kg per crew member per day.", 16, Color(0.75, 0.85, 0.9))
	_people_label = _create_label(vbox, "", 16, Color(0.75, 0.75, 0.75))
	_grade_label = _create_label(vbox, "", 32, Color(1.0, 0.9, 0.3))
	_new_best_label = _create_label(vbox, "", 18, Color(0.4, 1.0, 0.4))
	_notes_label = _create_label(vbox, "", 16, Color(0.8, 0.8, 0.8))
	_create_label(vbox, "HOW REAL CREWS COMPARE", 22, Color(0.6, 0.9, 1.0))
	for fact in COMPARISONS:
		_create_label(vbox, fact, 15, Color(0.8, 0.8, 0.8))
	_lost_label = _create_label(vbox, "Crew lost on this station before you: 0", 16, Color(0.7, 0.7, 0.7))
	_restart_btn = Button.new()
	_restart_btn.text = "New shift [R]"
	_restart_btn.custom_minimum_size = Vector2(220.0, 48.0)
	_restart_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_restart_btn.add_theme_font_size_override("font_size", 20)
	_restart_btn.process_mode = PROCESS_MODE_ALWAYS
	_restart_btn.pressed.connect(_restart)
	vbox.add_child(_restart_btn)
	_flash_rect = ColorRect.new()
	_flash_rect.name = "FlashRect"
	_flash_rect.color = Color(0.7, 1.0, 1.0, 0.0)
	_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash_rect)

func _create_label(parent: Control, text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(760.0, 0.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _on_shift_completed() -> void:
	_update_stats()
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_flash_rect.color.a = 0.4
	var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(_flash_rect, "color:a", 0.0, 0.5)
	tw.tween_callback(func() -> void:
		var sfx: Node = get_node_or_null("/root/Sfx")
		if sfx != null and sfx.has_method("play"):
			sfx.play("success")
	)

func _update_stats() -> void:
	var mm := _get_mm()
	var surv_secs_float := float(mm.survived_seconds) if mm != null else 0.0
	var fixes := int(mm.fixes_count) if mm != null else 0
	var close_calls := int(mm.get("close_calls")) if mm != null else 0
	var practice_mistakes := int(mm.get("practice_mistakes")) if mm != null else 0

	var surv_total := int(surv_secs_float)
	_summary_label.text = "You kept the habitat alive for %d:%02d and fixed %d failures." % [surv_total / 60, surv_total % 60, fixes]

	var grade_data := ShiftGrade.compute(fixes, close_calls, practice_mistakes, surv_secs_float, true)
	var score: int = int(grade_data.get("score", 0))
	var grade: String = String(grade_data.get("grade", "F"))
	var notes: Array = grade_data.get("notes", [])
	_grade_label.text = "GRADE %s  (%d/100)" % [grade, score]

	var is_new_best := false
	var sd := _get_save_data()
	if sd != null and score > int(sd.get_value("best_score", -1)):
		is_new_best = true
		sd.set_value("best_score", score)
		sd.set_value("best_grade", grade)
	_new_best_label.text = "NEW BEST" if is_new_best else ""
	_new_best_label.visible = is_new_best

	_notes_label.text = ", ".join(PackedStringArray(notes)) if not notes.is_empty() else ""
	_notes_label.visible = not notes.is_empty()

	_o2_label.text = "You breathed about %.1f g of oxygen. NASA plans for about 0.84 kg per crew member per day." % (840.0 * surv_secs_float / 86400.0)
	var pis: Node = get_node_or_null("/root/PeopleInSpace")
	if pis != null:
		_people_label.text = pis.summary_line()
	var mlog := _get_mission_log()
	var lost_count: int = (mlog.get("entries") as Array).size() if mlog != null and "entries" in mlog else 0
	_lost_label.text = "Crew lost on this station before you: %d" % lost_count

func _restart() -> void:
	get_tree().paused = false; get_tree().reload_current_scene()

func _connect_malfunction_manager() -> void:
	if not _connected and _get_mm() != null:
		_get_mm().shift_completed.connect(_on_shift_completed)
		_connected = true

func _get_mm() -> Node: return get_node_or_null("/root/MalfunctionManager")
func _get_mission_log() -> Node: return get_node_or_null("/root/MissionLog")
func _get_save_data() -> Node: return get_node_or_null("/root/SaveData")
