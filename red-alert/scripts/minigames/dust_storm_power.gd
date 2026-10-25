class_name DustStormPower
extends Minigame

const TOTAL_BUDGET: int = 90
const SYSTEM_NAMES: Array[String] = ["LIFE SUPPORT (min 40)", "HEATERS (min 25)", "COMMS (min 15)"]
const SYSTEM_MINS: Array[int] = [40, 25, 15]

var allocations: Array[int] = [33, 33, 33]
var _sliders: Array[HSlider] = []
var _value_labels: Array[Label] = []
var _total_label: Label
var _finished: bool = false


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS

	var content: VBoxContainer = make_panel("DUST STORM: BALANCE SOLAR POWER")
	if content == null:
		content = VBoxContainer.new()
		add_child(content)

	var panel: PanelContainer = get_node_or_null("MinigamePanel") as PanelContainer
	if panel != null:
		panel.custom_minimum_size = Vector2(680, 440)
		panel.offset_left = -340.0
		panel.offset_top = -220.0
		panel.offset_right = 340.0
		panel.offset_bottom = 220.0

	var desc := Label.new()
	desc.name = "DescLabel"
	desc.text = "Storm has cut solar output to 90%."
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 16)
	desc.add_theme_color_override("font_color", Color(1.0, 0.75, 0.3))
	content.add_child(desc)

	_sliders.clear()
	_value_labels.clear()

	for i in range(3):
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 16)
		content.add_child(row)

		var name_lbl := Label.new()
		name_lbl.text = SYSTEM_NAMES[i]
		name_lbl.custom_minimum_size = Vector2(220, 0)
		name_lbl.add_theme_font_size_override("font_size", 16)
		name_lbl.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
		row.add_child(name_lbl)

		var slider := HSlider.new()
		slider.min_value = 0
		slider.max_value = 60
		slider.step = 1
		slider.value = allocations[i]
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.custom_minimum_size = Vector2(200, 32)
		slider.value_changed.connect(func(val: float) -> void: set_allocation(i, int(round(val))))
		row.add_child(slider)
		_sliders.append(slider)

		var val_lbl := Label.new()
		val_lbl.custom_minimum_size = Vector2(90, 0)
		val_lbl.add_theme_font_size_override("font_size", 16)
		row.add_child(val_lbl)
		_value_labels.append(val_lbl)

	_total_label = Label.new()
	_total_label.name = "TotalLabel"
	_total_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_total_label.add_theme_font_size_override("font_size", 20)
	content.add_child(_total_label)

	var engage_btn := Button.new()
	engage_btn.name = "EngageButton"
	engage_btn.text = "ENGAGE"
	engage_btn.custom_minimum_size = Vector2(220, 44)
	engage_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	engage_btn.add_theme_font_size_override("font_size", 18)
	engage_btn.pressed.connect(engage)
	content.add_child(engage_btn)

	_update_ui()


func set_allocation(i: int, value: int) -> void:
	if i < 0 or i >= allocations.size():
		return
	allocations[i] = value
	if i < _sliders.size() and _sliders[i] != null and int(round(_sliders[i].value)) != value:
		_sliders[i].value = value
	_update_ui()


func engage() -> void:
	if _finished:
		return

	var total: int = allocations[0] + allocations[1] + allocations[2]
	if total > TOTAL_BUDGET:
		_finished = true
		fail("You drew more power than the panels could give and the batteries collapsed.")
	elif allocations[0] < SYSTEM_MINS[0]:
		_finished = true
		fail("You starved life support of power and the air stopped cycling.")
	elif allocations[1] < SYSTEM_MINS[1]:
		_finished = true
		fail("The heaters lost power and the water lines froze.")
	elif allocations[2] < SYSTEM_MINS[2]:
		_finished = true
		fail("Comms went dark and nobody heard the distress call.")
	else:
		_finished = true
		complete()


func _update_ui() -> void:
	var total: int = 0
	for i in range(allocations.size()):
		var val: int = allocations[i]
		total += val
		if i < _value_labels.size() and _value_labels[i] != null:
			var ok: bool = val >= SYSTEM_MINS[i]
			_value_labels[i].text = "%d  %s" % [val, "OK" if ok else "LOW"]
			_value_labels[i].modulate = Color(0.3, 0.9, 0.4) if ok else Color(1.0, 0.35, 0.2)

	if _total_label != null:
		if total > TOTAL_BUDGET:
			_total_label.text = "TOTAL %d / %d  OVER BUDGET" % [total, TOTAL_BUDGET]
			_total_label.modulate = Color(1.0, 0.3, 0.2)
		else:
			_total_label.text = "TOTAL %d / %d" % [total, TOTAL_BUDGET]
			_total_label.modulate = Color(0.3, 0.8, 1.0)
