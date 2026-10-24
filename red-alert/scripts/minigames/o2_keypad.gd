class_name O2Keypad
extends Minigame

## O2 filter reset keypad minigame.
## The player enters the 5-digit filter code displayed on screen.

const KEYS: Array[String] = [
	"1", "2", "3",
	"4", "5", "6",
	"7", "8", "9",
	"CLR", "0", "ENTER",
]

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

	var content: VBoxContainer = make_panel("O2: RESET FILTER") if has_method("make_panel") else null
	if content == null:
		content = VBoxContainer.new()
		content.name = "Content"
		add_child(content)

	content.add_theme_constant_override("separation", 14)

	code_label = Label.new()
	code_label.name = "CodeLabel"
	code_label.text = "FILTER CODE: " + code
	code_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	code_label.add_theme_font_size_override("font_size", 20)
	code_label.add_theme_color_override("font_color", Color(0.3, 0.85, 1.0))
	content.add_child(code_label)

	display_label = Label.new()
	display_label.name = "DisplayLabel"
	display_label.text = entered
	display_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	display_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	display_label.custom_minimum_size = Vector2(226, 42)
	display_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	display_label.add_theme_font_size_override("font_size", 24)
	display_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))

	var display_style := StyleBoxFlat.new()
	display_style.bg_color = Color(0.02, 0.04, 0.06, 0.95)
	display_style.border_color = Color(0.2, 0.5, 0.6, 0.8)
	display_style.set_border_width_all(2)
	display_style.set_corner_radius_all(4)
	display_label.add_theme_stylebox_override("normal", display_style)
	content.add_child(display_label)

	var grid := GridContainer.new()
	grid.name = "KeypadGrid"
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)

	for k: String in KEYS:
		var btn := Button.new()
		btn.name = "Key_" + k
		btn.text = k
		btn.custom_minimum_size = Vector2(70, 44)
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_size_override("font_size", 18)
		if k == "CLR":
			btn.add_theme_color_override("font_color", Color(0.95, 0.4, 0.4))
		elif k == "ENTER":
			btn.add_theme_color_override("font_color", Color(0.3, 0.9, 0.5))
		btn.pressed.connect(press_key.bind(k))
		grid.add_child(btn)

	content.add_child(grid)


func press_key(key: String) -> void:
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
		_:
			if key.length() == 1 and key >= "0" and key <= "9":
				if entered.length() < 5:
					entered += key
					if display_label != null:
						display_label.text = entered


static func _generate_code() -> String:
	var result := ""
	for i in range(5):
		result += str(randi_range(0, 9))
	return result
