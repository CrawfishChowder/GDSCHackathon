class_name PowerSwitches
extends Minigame

const LAMP_COLOR_LIT := Color(1.0, 0.75, 0.1)
const LAMP_COLOR_UNLIT := Color(0.15, 0.12, 0.05)

var target: Array[bool] = []
var switches: Array[bool] = []

var lamps: Array[ColorRect] = []
var buttons: Array[Button] = []
var status_label: Label = null

var _completed: bool = false


func _init() -> void:
	_init_target()


func _ready() -> void:
	if target.is_empty():
		_init_target()

	var content: VBoxContainer = make_panel("POWER: REROUTE BREAKERS")
	if content == null:
		content = VBoxContainer.new()
		add_child(content)

	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 24)

	var columns_row := HBoxContainer.new()
	columns_row.alignment = BoxContainer.ALIGNMENT_CENTER
	columns_row.add_theme_constant_override("separation", 20)
	columns_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(columns_row)

	lamps.clear()
	buttons.clear()

	for i in range(6):
		var col := VBoxContainer.new()
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_theme_constant_override("separation", 14)

		var lamp := ColorRect.new()
		lamp.custom_minimum_size = Vector2(40, 40)
		lamp.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		lamp.color = LAMP_COLOR_LIT if target[i] else LAMP_COLOR_UNLIT
		col.add_child(lamp)
		lamps.append(lamp)

		var btn := Button.new()
		btn.toggle_mode = true
		btn.button_pressed = switches[i]
		btn.text = "ON" if switches[i] else "OFF"
		btn.custom_minimum_size = Vector2(50, 40)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.pressed.connect(toggle.bind(i))
		col.add_child(btn)
		buttons.append(btn)

		columns_row.add_child(col)

	status_label = Label.new()
	status_label.text = "Match target pattern"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 18)
	status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	content.add_child(status_label)


func toggle(i: int) -> void:
	if _completed:
		return
	if i < 0 or i >= switches.size():
		return

	switches[i] = not switches[i]
	if i < buttons.size():
		var btn: Button = buttons[i]
		btn.button_pressed = switches[i]
		btn.text = "ON" if switches[i] else "OFF"

	if switches == target:
		_completed = true
		for btn: Button in buttons:
			btn.disabled = true
		if status_label != null:
			status_label.text = "Power restored"
			status_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
		var tree := get_tree()
		if tree != null:
			await tree.create_timer(0.3, true, false, true).timeout
			if not is_inside_tree():
				return
		complete()


func _init_target() -> void:
	target.clear()
	switches.clear()
	for i in range(6):
		switches.append(false)

	while true:
		target.clear()
		var true_count: int = 0
		for i in range(6):
			var val: bool = randf() >= 0.5
			target.append(val)
			if val:
				true_count += 1
		if true_count >= 2 and true_count <= 4:
			break
