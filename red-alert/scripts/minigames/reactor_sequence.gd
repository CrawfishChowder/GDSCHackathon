class_name ReactorSequence
extends Minigame

const BASE_COLORS: Array[Color] = [
	Color(0.72, 0.12, 0.12), Color(0.82, 0.52, 0.08),
	Color(0.12, 0.42, 0.82), Color(0.12, 0.65, 0.22),
]
const BRIGHT_COLORS: Array[Color] = [
	Color(1.0, 0.35, 0.35), Color(1.0, 0.88, 0.3),
	Color(0.4, 0.78, 1.0), Color(0.38, 1.0, 0.52),
]

var sequence: Array[int] = []
var accepting_input: bool = false

var _current_step: int = 0
var _buttons: Array[Button] = []
var _status_label: Label = null
var _normal_styles: Array[StyleBoxFlat] = []
var _bright_styles: Array[StyleBoxFlat] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	var content: VBoxContainer = make_panel("REACTOR: STABILIZE CORE")
	if content == null:
		content = VBoxContainer.new()
		add_child(content)

	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 24)

	var button_row := HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.add_theme_constant_override("separation", 16)
	content.add_child(button_row)

	for i in range(4):
		_normal_styles.append(_create_style(BASE_COLORS[i], false))
		_bright_styles.append(_create_style(BRIGHT_COLORS[i], true))

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(110, 110)
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_stylebox_override("normal", _normal_styles[i])
		btn.add_theme_stylebox_override("hover", _normal_styles[i])
		btn.add_theme_stylebox_override("pressed", _bright_styles[i])
		btn.add_theme_stylebox_override("disabled", _normal_styles[i])

		var button_index: int = i
		btn.pressed.connect(func() -> void: press(button_index))
		button_row.add_child(btn)
		_buttons.append(btn)

	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.text = "Watch the sequence"
	_status_label.add_theme_font_size_override("font_size", 18)
	_status_label.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95))
	content.add_child(_status_label)

	if sequence.is_empty():
		for _i in range(4):
			sequence.append(randi_range(0, 3))

	_play_sequence()


func press(index: int) -> void:
	if not accepting_input:
		return

	var sfx: Node = get_node_or_null("/root/Sfx")
	if sfx != null and sfx.has_method("play"):
		sfx.play("click")

	if index == sequence[_current_step]:
		_current_step += 1
		if _current_step >= sequence.size():
			accepting_input = false
			if _status_label != null:
				_status_label.text = "Core stabilized"
			complete()
	else:
		accepting_input = false
		fail("You pressed the wrong control in the sequence and pulled the core out of safe limits.")


func _play_sequence() -> void:
	accepting_input = false
	_current_step = 0
	if _status_label != null:
		_status_label.text = "Watch the sequence"

	for idx in sequence:
		if not is_inside_tree():
			return
		_set_button_lit(idx, true)
		var sfx: Node = get_node_or_null("/root/Sfx")
		if sfx != null and sfx.has_method("play"):
			sfx.play("beep")
		await get_tree().create_timer(0.4, true, false, true).timeout
		if not is_inside_tree():
			return
		_set_button_lit(idx, false)
		await get_tree().create_timer(0.15, true, false, true).timeout

	if not is_inside_tree():
		return

	accepting_input = true
	if _status_label != null:
		_status_label.text = "Repeat the pattern"


func _create_style(color: Color, border: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(8)
	if border:
		style.set_border_width_all(3)
		style.border_color = Color(1.0, 1.0, 1.0, 0.9)
	return style


func _set_button_lit(index: int, lit: bool) -> void:
	if index >= 0 and index < _buttons.size():
		var style: StyleBoxFlat = _bright_styles[index] if lit else _normal_styles[index]
		_buttons[index].add_theme_stylebox_override("normal", style)
		_buttons[index].add_theme_stylebox_override("hover", style)
		_buttons[index].add_theme_stylebox_override("disabled", style)
