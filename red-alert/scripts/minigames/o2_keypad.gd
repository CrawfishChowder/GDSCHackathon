class_name O2Keypad
extends Minigame

## O2 filter reset keypad minigame.
## The player enters the 5-digit filter code displayed on screen.
## Emits completed or failed to MinigameHost; one wrong code vents oxygen.

const KEYS: Array[String] = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "CLR", "0", "ENTER"]

var code: String = ""
var entered: String = ""
var code_label: Label = null
var display_label: Label = null

func _init() -> void:
	if code.is_empty():
		code = _generate_code()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if code.is_empty():
		code = _generate_code()

	var content: VBoxContainer = null
	if has_method("make_panel"):
		content = make_panel("O2: RESET FILTER")
	if content == null:
		content = VBoxContainer.new()
		content.name = "Content"
		add_child(content)

	add_instruction(content, "Type the filter code shown above, then press ENTER. One wrong code is fatal.")
	content.add_theme_constant_override("separation", 14)

	code_label = Label.new()
	code_label.name = "CodeLabel"; code_label.text = "FILTER CODE: " + code
	code_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	code_label.add_theme_font_size_override("font_size", 20)
	code_label.add_theme_color_override("font_color", Color(0.3, 0.85, 1.0))
	content.add_child(code_label)

	display_label = Label.new()
	display_label.name = "DisplayLabel"; display_label.text = entered
	display_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	display_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	display_label.custom_minimum_size = Vector2(226, 42)
	display_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	display_label.add_theme_font_size_override("font_size", 24)
	display_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))

	var display_style := StyleBoxFlat.new()
	display_style.bg_color = Color(0.02, 0.04, 0.06, 0.95)
	display_style.border_color = Color(0.2, 0.5, 0.6, 0.8)
	display_style.set_border_width_all(2); display_style.set_corner_radius_all(4)
	display_label.add_theme_stylebox_override("normal", display_style)
	content.add_child(display_label)

	var grid := GridContainer.new()
	grid.name = "KeypadGrid"; grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation", 8); grid.add_theme_constant_override("v_separation", 8)

	for k: String in KEYS:
		var btn := Button.new()
		btn.name = "Key_" + k; btn.custom_minimum_size = Vector2(80, 44); btn.focus_mode = Control.FOCUS_NONE
		if k == "CLR":
			btn.text = "CLR [Bksp]"
			btn.add_theme_font_size_override("font_size", 13)
			btn.add_theme_color_override("font_color", Color(0.95, 0.4, 0.4))
		elif k == "ENTER":
			btn.text = "ENTER [Enter]"
			btn.add_theme_font_size_override("font_size", 12)
			btn.add_theme_color_override("font_color", Color(0.3, 0.9, 0.5))
		else:
			btn.text = "[%s]" % k
			btn.add_theme_font_size_override("font_size", 18)
		btn.pressed.connect(press_key.bind(k))
		grid.add_child(btn)

	content.add_child(grid)

func _unhandled_input(event: InputEvent) -> void:
	if _done or not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	var keycode := key_event.keycode
	if keycode == KEY_NONE:
		keycode = key_event.physical_keycode

	var handled := false
	if keycode >= KEY_0 and keycode <= KEY_9:
		press_key(str(keycode - KEY_0))
		handled = true
	elif keycode >= KEY_KP_0 and keycode <= KEY_KP_9:
		press_key(str(keycode - KEY_KP_0))
		handled = true
	elif keycode == KEY_BACKSPACE:
		press_key("CLR")
		handled = true
	elif keycode == KEY_ENTER or keycode == KEY_KP_ENTER:
		press_key("ENTER")
		handled = true

	if handled:
		var vp := get_viewport()
		if vp != null:
			vp.set_input_as_handled()

## Processes keypad input for digits, CLR, and ENTER.
func press_key(key: String) -> void:
	if _done:
		return

	var sfx: Node = get_node_or_null("/root/Sfx")
	if sfx != null and sfx.has_method("play"):
		var sound: String = "click"
		if key.length() == 1 and key >= "0" and key <= "9":
			sound = "beep"
		sfx.play(sound)

	match key.to_upper():
		"CLR":
			entered = ""
			if display_label != null:
				display_label.text = ""
		"ENTER":
			if entered == code:
				complete()
			else:
				entered = ""
				if display_label != null:
					display_label.text = "ERROR"
				fail("You entered the wrong code and vented the oxygen supply.")
		_:
			if key.length() == 1 and key >= "0" and key <= "9" and entered.length() < 5:
				entered += key
				if display_label != null:
					display_label.text = entered

static func _generate_code() -> String:
	var result := ""
	for i in range(5):
		result += str(randi_range(0, 9))
	return result
