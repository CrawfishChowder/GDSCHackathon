class_name ReactorValves
extends Minigame

## Reactor coolant loop balancing minigame.
## The player toggles valves 1-3 to keep all three coolant loops within the 40-70 green band.
## Emits completed after 3.0s continuous stability; failing over 90 ruptures the loop.

const INFLOW: Array[float] = [6.0, 9.0, 4.0]
const OUTFLOW: Array[float] = [10.0, 14.0, 12.0]
const GREEN_MIN: float = 40.0
const GREEN_MAX: float = 70.0
const RUPTURE_PRESSURE: float = 90.0
const REQUIRED_HOLD_TIME: float = 3.0

var pressure: Array[float] = [45.0, 45.0, 45.0]
var valve_open: Array[bool] = [false, false, false]
var _green_time: float = 0.0
var _progress_bars: Array[ProgressBar] = []
var _status_labels: Array[Label] = []
var _valve_buttons: Array[Button] = []
var _stability_label: Label = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	var content: VBoxContainer = make_panel("REACTOR: BALANCE THE COOLANT LOOPS")
	if content == null:
		content = VBoxContainer.new()
		add_child(content)

	add_instruction(content, "Open and close valves to keep all three loops in the green band for 3 seconds. Any loop in the red is fatal.")

	var panel: PanelContainer = get_node_or_null("MinigamePanel") as PanelContainer
	if panel != null:
		panel.custom_minimum_size = Vector2(680, 440)
		panel.offset_left = -340.0
		panel.offset_top = -220.0
		panel.offset_right = 340.0
		panel.offset_bottom = 220.0
		_base_l = -340.0
		_base_t = -220.0
		_base_r = 340.0
		_base_b = 220.0

	_progress_bars.clear()
	_status_labels.clear()
	_valve_buttons.clear()

	var loops_box := VBoxContainer.new()
	loops_box.name = "LoopsBox"
	loops_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	loops_box.add_theme_constant_override("separation", 16)
	content.add_child(loops_box)

	for i: int in range(3):
		var row := HBoxContainer.new()
		row.name = "LoopRow%d" % (i + 1)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 14)
		loops_box.add_child(row)

		var name_lbl := Label.new()
		name_lbl.name = "NameLabel%d" % (i + 1)
		name_lbl.text = "LOOP %d" % (i + 1)
		name_lbl.custom_minimum_size = Vector2(75, 0)
		name_lbl.add_theme_font_size_override("font_size", 16)
		name_lbl.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
		row.add_child(name_lbl)

		var bar := ProgressBar.new()
		bar.name = "ProgressBar%d" % (i + 1)
		bar.min_value = 0.0
		bar.max_value = 100.0
		bar.step = 0.1
		bar.value = pressure[i]
		bar.show_percentage = true
		bar.custom_minimum_size = Vector2(220, 28)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(bar)
		_progress_bars.append(bar)

		var status_lbl := Label.new()
		status_lbl.name = "StatusLabel%d" % (i + 1)
		status_lbl.text = "OK"
		status_lbl.custom_minimum_size = Vector2(85, 0)
		status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status_lbl.add_theme_font_size_override("font_size", 16)
		row.add_child(status_lbl)
		_status_labels.append(status_lbl)

		var btn := Button.new()
		btn.name = "ValveButton%d" % (i + 1)
		btn.text = "Valve %d [%d]" % [i + 1, i + 1]
		btn.toggle_mode = true
		btn.button_pressed = valve_open[i]
		btn.custom_minimum_size = Vector2(140, 38)
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_size_override("font_size", 15)
		var loop_idx: int = i
		btn.toggled.connect(func(pressed: bool) -> void:
			if valve_open[loop_idx] != pressed:
				var sfx: Node = get_node_or_null("/root/Sfx")
				if sfx != null and sfx.has_method("play"):
					sfx.play("click")
				set_valve(loop_idx, pressed)
		)
		row.add_child(btn)
		_valve_buttons.append(btn)
		_update_valve_button_visual(i)

	_stability_label = Label.new()
	_stability_label.name = "StabilityLabel"
	_stability_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stability_label.add_theme_font_size_override("font_size", 18)
	_stability_label.add_theme_color_override("font_color", Color(0.3, 0.85, 1.0))
	content.add_child(_stability_label)

	_update_ui()


func _process(delta: float) -> void:
	super._process(delta)
	if _done:
		return
	step_sim(delta)


func _unhandled_input(event: InputEvent) -> void:
	if _done:
		return
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	var keycode := key_event.keycode
	if keycode == KEY_NONE:
		keycode = key_event.physical_keycode

	var idx: int = -1
	if keycode >= KEY_1 and keycode <= KEY_3:
		idx = keycode - KEY_1
	elif keycode >= KEY_KP_1 and keycode <= KEY_KP_3:
		idx = keycode - KEY_KP_1

	if idx >= 0 and idx < 3:
		var vp := get_viewport()
		if vp != null:
			vp.set_input_as_handled()
		toggle_valve(idx)


func step_sim(delta: float) -> void:
	if _done:
		return

	for i: int in range(3):
		var outflow_val: float = 0.0
		if valve_open[i]:
			outflow_val = OUTFLOW[i]
		var rate: float = INFLOW[i] - outflow_val
		pressure[i] += rate * delta
		if pressure[i] < 0.0:
			pressure[i] = 0.0

	for i: int in range(3):
		if pressure[i] > RUPTURE_PRESSURE:
			_update_ui()
			fail("A coolant loop over-pressurized and ruptured. The core lost cooling.")
			return

	var all_in_green: bool = true
	for i: int in range(3):
		if pressure[i] < GREEN_MIN or pressure[i] > GREEN_MAX:
			all_in_green = false
			break

	if all_in_green:
		_green_time += delta
		if _green_time >= REQUIRED_HOLD_TIME:
			_update_ui()
			complete()
			return
	else:
		_green_time = 0.0

	_update_ui()


func set_valve(i: int, open: bool) -> void:
	if i < 0 or i >= 3:
		return
	valve_open[i] = open
	if i < _valve_buttons.size() and is_instance_valid(_valve_buttons[i]):
		if _valve_buttons[i].button_pressed != open:
			_valve_buttons[i].button_pressed = open
		_update_valve_button_visual(i)


func toggle_valve(i: int) -> void:
	if _done:
		return
	if i < 0 or i >= 3:
		return
	var sfx: Node = get_node_or_null("/root/Sfx")
	if sfx != null and sfx.has_method("play"):
		sfx.play("click")
	set_valve(i, not valve_open[i])


func _update_ui() -> void:
	for i: int in range(3):
		if i < _progress_bars.size() and is_instance_valid(_progress_bars[i]):
			_progress_bars[i].value = pressure[i]

		if i < _status_labels.size() and is_instance_valid(_status_labels[i]):
			var p: float = pressure[i]
			var status_text: String = ""
			var status_color: Color = Color.WHITE

			if p < GREEN_MIN:
				status_text = "LOW"
				status_color = Color(0.3, 0.75, 1.0)
			elif p <= GREEN_MAX:
				status_text = "OK"
				status_color = Color(0.3, 0.9, 0.4)
			elif p <= 85.0:
				status_text = "HIGH"
				status_color = Color(1.0, 0.75, 0.2)
			else:
				status_text = "CRITICAL"
				status_color = Color(1.0, 0.3, 0.3)

			_status_labels[i].text = status_text
			_status_labels[i].add_theme_color_override("font_color", status_color)

	if is_instance_valid(_stability_label):
		if _green_time > 0.0:
			_stability_label.text = "STABILIZING: %.1f / 3.0s" % minf(_green_time, REQUIRED_HOLD_TIME)
			_stability_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))
		else:
			_stability_label.text = "HOLD TIME: 0.0 / 3.0s (KEEP IN GREEN 40-70)"
			_stability_label.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95))


func _update_valve_button_visual(i: int) -> void:
	if i < 0 or i >= _valve_buttons.size():
		return
	var btn: Button = _valve_buttons[i]
	if not is_instance_valid(btn):
		return
	if valve_open[i]:
		btn.add_theme_color_override("font_color", Color(0.3, 0.9, 0.5))
	else:
		btn.remove_theme_color_override("font_color")
