class_name CO2Adapter
extends Minigame

## CO2 scrubber adapter minigame (Apollo 13 emergency).
## Player must follow the 4-step procedure in exact order.

const STEPS: Array[String] = [
	"Cut the hose",
	"Wrap the cartridge in a plastic bag",
	"Tape the bag to the hose",
	"Seal the edges with duct tape",
]

var order: Array[int] = []

var _current_step: int = 0
var _step_labels: Array[Label] = []
var _buttons: Array[Button] = []
var _finished: bool = false


func _init() -> void:
	if order.is_empty():
		_init_order()


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	if order.is_empty():
		_init_order()

	var content: VBoxContainer = make_panel("CO2: BUILD THE SCRUBBER ADAPTER")
	if content == null:
		content = VBoxContainer.new()
		add_child(content)

	var panel: PanelContainer = get_node_or_null("MinigamePanel") as PanelContainer
	if panel != null:
		panel.custom_minimum_size = Vector2(720, 440)
		panel.offset_left = -360.0
		panel.offset_top = -220.0
		panel.offset_right = 360.0
		panel.offset_bottom = 220.0

	var hbox := HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 24)
	content.add_child(hbox)

	var proc_box := VBoxContainer.new()
	proc_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	proc_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	proc_box.add_theme_constant_override("separation", 16)
	hbox.add_child(proc_box)

	var proc_title := Label.new()
	proc_title.text = "PROCEDURE (read over the radio)"
	proc_title.add_theme_font_size_override("font_size", 16)
	proc_title.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
	proc_box.add_child(proc_title)

	_step_labels.clear()
	for i in range(STEPS.size()):
		var step_lbl := Label.new()
		step_lbl.text = "%d. %s" % [i + 1, STEPS[i]]
		step_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		step_lbl.add_theme_font_size_override("font_size", 15)
		step_lbl.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
		proc_box.add_child(step_lbl)
		_step_labels.append(step_lbl)

	var btn_box := VBoxContainer.new()
	btn_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	btn_box.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_box.add_theme_constant_override("separation", 10)
	hbox.add_child(btn_box)

	_buttons.clear()
	for i in range(order.size()):
		var step_idx: int = order[i]
		var btn := Button.new()
		btn.text = STEPS[step_idx]
		btn.custom_minimum_size = Vector2(280, 48)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_size_override("font_size", 14)
		btn.pressed.connect(press_step.bind(step_idx))
		btn_box.add_child(btn)
		_buttons.append(btn)


func press_step(step_index: int) -> void:
	if _finished:
		return

	var sfx: Node = get_node_or_null("/root/Sfx")
	if sfx != null and sfx.has_method("play"):
		sfx.play("click")

	if step_index == _current_step:
		if _current_step < _step_labels.size() and _step_labels[_current_step] != null:
			_step_labels[_current_step].text = "✓ %d. %s" % [_current_step + 1, STEPS[_current_step]]
			_step_labels[_current_step].add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))

		for i in range(order.size()):
			if order[i] == step_index and i < _buttons.size() and _buttons[i] != null:
				_buttons[i].disabled = true
				_buttons[i].add_theme_color_override("font_disabled_color", Color(0.45, 0.45, 0.45))

		_current_step += 1
		if _current_step >= STEPS.size():
			_finished = true
			complete()
	else:
		_finished = true
		fail("You skipped a step and the adapter leaked. The cabin filled with carbon dioxide.")


func _init_order() -> void:
	order = [0, 1, 2, 3]
	while order == [0, 1, 2, 3]:
		order.shuffle()
