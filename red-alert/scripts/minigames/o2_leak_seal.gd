class_name O2LeakSeal
extends Minigame

## O2 leak seal minigame.
## The player identifies the joint with the lowest line pressure and seals it.
## Emits completed or failed to MinigameHost; sealing a healthy joint vents the line.

var leak_index: int = -1
var pressures: Array[float] = []
var buttons: Array[Button] = []


func _init() -> void:
	if leak_index < 0:
		_setup_joints()


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	if leak_index < 0 or pressures.size() != 9:
		_setup_joints()

	var content: VBoxContainer = make_panel("O2: SEAL THE LEAKING JOINT")
	if content == null:
		content = VBoxContainer.new()
		content.name = "Content"
		add_child(content)

	add_instruction(
		content,
		"Every joint shows its line pressure. The leaking joint reads lowest. Seal it. Sealing a healthy joint vents the line."
	)

	var panel: PanelContainer = get_node_or_null("MinigamePanel") as PanelContainer
	if panel != null:
		panel.custom_minimum_size = Vector2(640, 440)
		panel.offset_left = -320.0
		panel.offset_top = -220.0
		panel.offset_right = 320.0
		panel.offset_bottom = 220.0
		_base_l = -320.0
		_base_t = -220.0
		_base_r = 320.0
		_base_b = 220.0

	var grid := GridContainer.new()
	grid.name = "JointGrid"
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)

	buttons.clear()
	for i in range(9):
		var btn := Button.new()
		btn.name = "JointButton_%d" % (i + 1)
		btn.custom_minimum_size = Vector2(170, 52)
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_size_override("font_size", 14)
		btn.text = _format_button_text(i)
		btn.pressed.connect(seal.bind(i))
		grid.add_child(btn)
		buttons.append(btn)

	content.add_child(grid)


func _process(delta: float) -> void:
	super._process(delta)
	if _done:
		return
	if leak_index >= 0 and leak_index < pressures.size():
		pressures[leak_index] = maxf(0.0, pressures[leak_index] - 0.4 * delta)
		if leak_index < buttons.size() and buttons[leak_index] != null:
			buttons[leak_index].text = _format_button_text(leak_index)


func _unhandled_input(event: InputEvent) -> void:
	if _done or not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	var keycode := key_event.keycode
	if keycode == KEY_NONE:
		keycode = key_event.physical_keycode

	var idx := -1
	if keycode >= KEY_1 and keycode <= KEY_9:
		idx = keycode - KEY_1
	elif keycode >= KEY_KP_1 and keycode <= KEY_KP_9:
		idx = keycode - KEY_KP_1

	if idx >= 0 and idx < 9:
		var vp := get_viewport()
		if vp != null:
			vp.set_input_as_handled()
		seal(idx)


func seal(i: int) -> void:
	if _done:
		return
	if i < 0 or i >= 9:
		return

	if is_inside_tree():
		var sfx: Node = get_node_or_null("/root/Sfx")
		if sfx != null and sfx.has_method("play"):
			sfx.play("click")

	if i == leak_index:
		if i < buttons.size() and buttons[i] != null:
			buttons[i].modulate = Color(0.3, 0.9, 0.5)
		complete()
	else:
		if i < buttons.size() and buttons[i] != null:
			buttons[i].modulate = Color(0.95, 0.3, 0.3)
		fail("You sealed a healthy joint and vented the oxygen line instead.")


func _setup_joints() -> void:
	if leak_index < 0 or leak_index > 8:
		leak_index = randi_range(0, 8)
	pressures.resize(9)
	for i in range(9):
		if i == leak_index:
			pressures[i] = randf_range(82.0, 90.0)
		else:
			pressures[i] = randf_range(99.0, 102.0)


func _format_button_text(i: int) -> String:
	if i < 0 or i >= pressures.size():
		return "J%d [%d]" % [i + 1, i + 1]
	return "J%d [%d]\n%.1f kPa" % [i + 1, i + 1, pressures[i]]
