class_name ReactorSequence
extends Minigame

## Reactor core stabilization memory sequence minigame.
## Plays back a 4-step color pattern for the player to repeat.
## Emits completed or failed to MinigameHost; one wrong press pulls core out of limits.

const BASE_COLORS: Array[Color] = [Color(0.72, 0.12, 0.12), Color(0.82, 0.52, 0.08), Color(0.12, 0.42, 0.82), Color(0.12, 0.65, 0.22)]
const BRIGHT_COLORS: Array[Color] = [Color(1.0, 0.35, 0.35), Color(1.0, 0.88, 0.3), Color(0.4, 0.78, 1.0), Color(0.38, 1.0, 0.52)]

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

	add_instruction(content, "Watch the sequence, then repeat it. A single wrong press is fatal.")
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
		btn.text = "[%d]" % (i + 1)
		btn.custom_minimum_size = Vector2(110, 110)
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_size_override("font_size", 28)
		btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.9))
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
	ControllerSupport.focus_buttons(self, true)

## Handles player input on button index (0-3), comparing against sequence.
func press(index: int) -> void:
	if _done or not accepting_input:
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

func _unhandled_input(event: InputEvent) -> void:
	if _done or not accepting_input or not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	var keycode := key_event.keycode
	if keycode == KEY_NONE:
		keycode = key_event.physical_keycode

	var idx := -1
	if keycode >= KEY_1 and keycode <= KEY_4:
		idx = keycode - KEY_1
	elif keycode >= KEY_KP_1 and keycode <= KEY_KP_4:
		idx = keycode - KEY_KP_1

	if idx >= 0 and idx < 4:
		var vp := get_viewport()
		if vp != null:
			vp.set_input_as_handled()
		press(idx)

## Plays back the Simon-style pattern before accepting player input.
func _play_sequence() -> void:
	accepting_input = false
	_current_step = 0
	if _status_label != null:
		_status_label.text = "Watch the sequence"

	for idx: int in sequence:
		if _done or not is_inside_tree():
			return
		_set_button_lit(idx, true)
		var sfx: Node = get_node_or_null("/root/Sfx")
		if sfx != null and sfx.has_method("play"):
			sfx.play("beep")

		var tree: SceneTree = get_tree()
		if tree == null or _done or not is_inside_tree():
			return
		await tree.create_timer(0.4, true, false, true).timeout
		if _done or not is_inside_tree():
			return

		_set_button_lit(idx, false)

		tree = get_tree()
		if tree == null or _done or not is_inside_tree():
			return
		await tree.create_timer(0.15, true, false, true).timeout
		if _done or not is_inside_tree():
			return

	if _done or not is_inside_tree():
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
		var btn: Button = _buttons[index]
		if is_instance_valid(btn):
			var style: StyleBoxFlat = _bright_styles[index] if lit else _normal_styles[index]
			btn.add_theme_stylebox_override("normal", style)
			btn.add_theme_stylebox_override("hover", style)
			btn.add_theme_stylebox_override("disabled", style)
