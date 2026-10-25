class_name DustStormPower
extends Minigame

## Solar power rebalancing minigame during dust storms.
## The player adjusts allocations across life support, heaters, and comms within budget.
## Emits completed or failed to MinigameHost; starving a system or blowing budget is fatal.

const TOTAL_BUDGET: int = 90
const SYSTEM_NAMES: Array[String] = ["LIFE SUPPORT (min 40)", "HEATERS (min 25)", "COMMS (min 15)"]
const SYSTEM_MINS: Array[int] = [40, 25, 15]

var allocations: Array[int] = [33, 33, 33]
var _sliders: Array[HSlider] = []
var _value_labels: Array[Label] = []
var _total_label: Label = null
var _last_slider_sfx_msec: int = -100

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS

	var content: VBoxContainer = make_panel("DUST STORM: BALANCE SOLAR POWER")
	if content == null:
		content = VBoxContainer.new()
		add_child(content)

	add_instruction(content, "Drag the sliders so every system is at or above its minimum and the total is 90 or less, then ENGAGE.")

	var panel: PanelContainer = get_node_or_null("MinigamePanel") as PanelContainer
	if panel != null:
		panel.custom_minimum_size = Vector2(680, 440)
		panel.offset_left = -340.0
		panel.offset_top = -220.0
		panel.offset_right = 340.0
		panel.offset_bottom = 220.0

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
		slider.focus_mode = Control.FOCUS_ALL
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
	engage_btn.text = "ENGAGE [Enter]"
	engage_btn.focus_mode = Control.FOCUS_NONE
	engage_btn.custom_minimum_size = Vector2(220, 44)
	engage_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	engage_btn.add_theme_font_size_override("font_size", 18)
	engage_btn.pressed.connect(engage)
	content.add_child(engage_btn)

	_update_ui()

func _unhandled_input(event: InputEvent) -> void:
	if _done or not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	var keycode := key_event.keycode
	if keycode == KEY_NONE:
		keycode = key_event.physical_keycode
	if keycode == KEY_ENTER or keycode == KEY_KP_ENTER:
		var vp := get_viewport()
		if vp != null:
			vp.set_input_as_handled()
		engage()

## Sets allocation for a subsystem index and updates UI and sound.
func set_allocation(i: int, value: int) -> void:
	if _done or i < 0 or i >= allocations.size():
		return
	var changed: bool = (allocations[i] != value)
	allocations[i] = value
	if i < _sliders.size() and _sliders[i] != null and int(round(_sliders[i].value)) != value:
		_sliders[i].value = value
	_update_ui()
	if changed:
		var now: int = Time.get_ticks_msec()
		if now - _last_slider_sfx_msec >= 80:
			_last_slider_sfx_msec = now
			var sfx: Node = get_node_or_null("/root/Sfx")
			if sfx != null and sfx.has_method("play"):
				sfx.play("click")

## Validates power totals and system minimums, completing or failing the minigame.
func engage() -> void:
	if _done:
		return
	var sfx: Node = get_node_or_null("/root/Sfx")
	if sfx != null and sfx.has_method("play"):
		sfx.play("click")

	var total: int = allocations[0] + allocations[1] + allocations[2]
	if total > TOTAL_BUDGET:
		fail("You drew more power than the panels could give and the batteries collapsed.")
	elif allocations[0] < SYSTEM_MINS[0]:
		fail("You starved life support of power and the air stopped cycling.")
	elif allocations[1] < SYSTEM_MINS[1]:
		fail("The heaters lost power and the water lines froze.")
	elif allocations[2] < SYSTEM_MINS[2]:
		fail("Comms went dark and nobody heard the distress call.")
	else:
		complete()

func _update_ui() -> void:
	var total: int = 0
	for i in range(allocations.size()):
		var val: int = allocations[i]
		total += val
		if i < _value_labels.size() and _value_labels[i] != null:
			var ok: bool = val >= SYSTEM_MINS[i]
			var status_str: String = "OK" if ok else "LOW"
			_value_labels[i].text = "%d  %s" % [val, status_str]
			_value_labels[i].modulate = Color(0.3, 0.9, 0.4) if ok else Color(1.0, 0.35, 0.2)

	if _total_label != null:
		var over: bool = total > TOTAL_BUDGET
		if over:
			_total_label.text = "TOTAL %d / %d  OVER BUDGET" % [total, TOTAL_BUDGET]
			_total_label.modulate = Color(1.0, 0.3, 0.2)
		else:
			_total_label.text = "TOTAL %d / %d" % [total, TOTAL_BUDGET]
			_total_label.modulate = Color(0.3, 0.8, 1.0)
