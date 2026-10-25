class_name DustPanelAlign
extends Minigame

## Solar panel tilt alignment minigame during dust storms.
## The player rotates the array to match the flickering sun bearing within ±5°.
## Emits completed or failed to MinigameHost; locking off target drains batteries.

const HOLD_INITIAL_DELAY: float = 0.25
const HOLD_REPEAT_INTERVAL: float = 0.05

var sun_bearing: int = 0
var array_deg: int = 0

var sun_label: Label = null
var array_label: Label = null
var btn_left: Button = null
var btn_right: Button = null
var lock_btn: Button = null

var _flicker_timer: float = 0.0
var _flicker_visible: bool = true
var _hold_dir: int = 0
var _hold_time: float = 0.0
var _repeat_timer: float = 0.0


func _init() -> void:
	if sun_bearing == 0:
		sun_bearing = randi_range(20, 160)


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	if sun_bearing == 0:
		sun_bearing = randi_range(20, 160)

	_flicker_timer = randf_range(0.3, 0.6)
	_flicker_visible = true

	var content: VBoxContainer = make_panel("DUST STORM: TILT THE SOLAR ARRAY")
	if content == null:
		content = VBoxContainer.new()
		add_child(content)

	add_instruction(
		content,
		"Through the dust, the sun bearing flickers on the readout. "
		+ "Rotate the array to within 5 degrees of it, then LOCK. "
		+ "Locking far off target drains the batteries."
	)

	var panel: PanelContainer = get_node_or_null("MinigamePanel") as PanelContainer
	if panel != null:
		panel.custom_minimum_size = Vector2(680, 420)
		panel.offset_left = -340.0
		panel.offset_top = -210.0
		panel.offset_right = 340.0
		panel.offset_bottom = 210.0
		_base_l = -340.0
		_base_t = -210.0
		_base_r = 340.0
		_base_b = 210.0

	var sun_panel := PanelContainer.new()
	sun_panel.name = "SunPanel"
	sun_panel.custom_minimum_size = Vector2(340, 52)
	sun_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var sun_style := StyleBoxFlat.new()
	sun_style.bg_color = Color(0.02, 0.04, 0.06, 0.95)
	sun_style.border_color = Color(0.9, 0.65, 0.15, 0.8)
	sun_style.set_border_width_all(2)
	sun_style.set_corner_radius_all(6)
	sun_panel.add_theme_stylebox_override("panel", sun_style)

	sun_label = Label.new()
	sun_label.name = "SunLabel"
	sun_label.text = "SUN BEARING: %d°" % sun_bearing
	sun_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sun_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sun_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sun_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sun_label.add_theme_font_size_override("font_size", 22)
	sun_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	sun_panel.add_child(sun_label)
	content.add_child(sun_panel)

	var array_row := HBoxContainer.new()
	array_row.name = "ArrayRow"
	array_row.alignment = BoxContainer.ALIGNMENT_CENTER
	array_row.add_theme_constant_override("separation", 14)
	content.add_child(array_row)

	btn_left = Button.new()
	btn_left.name = "LeftButton"
	btn_left.text = "◀ [A]"
	btn_left.custom_minimum_size = Vector2(88, 48)
	btn_left.focus_mode = Control.FOCUS_NONE
	btn_left.add_theme_font_size_override("font_size", 16)
	btn_left.button_down.connect(func() -> void: _start_hold(-1))
	btn_left.button_up.connect(_stop_hold)
	array_row.add_child(btn_left)

	var array_panel := PanelContainer.new()
	array_panel.name = "ArrayPanel"
	array_panel.custom_minimum_size = Vector2(240, 48)

	var array_style := StyleBoxFlat.new()
	array_style.bg_color = Color(0.02, 0.04, 0.06, 0.95)
	array_style.border_color = Color(0.2, 0.5, 0.8, 0.8)
	array_style.set_border_width_all(2)
	array_style.set_corner_radius_all(6)
	array_panel.add_theme_stylebox_override("panel", array_style)

	array_label = Label.new()
	array_label.name = "ArrayLabel"
	array_label.text = "ARRAY: %d°" % array_deg
	array_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	array_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	array_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	array_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	array_label.add_theme_font_size_override("font_size", 22)
	array_label.add_theme_color_override("font_color", Color(0.3, 0.85, 1.0))
	array_panel.add_child(array_label)
	array_row.add_child(array_panel)

	btn_right = Button.new()
	btn_right.name = "RightButton"
	btn_right.text = "▶ [D]"
	btn_right.custom_minimum_size = Vector2(88, 48)
	btn_right.focus_mode = Control.FOCUS_NONE
	btn_right.add_theme_font_size_override("font_size", 16)
	btn_right.button_down.connect(func() -> void: _start_hold(1))
	btn_right.button_up.connect(_stop_hold)
	array_row.add_child(btn_right)

	lock_btn = Button.new()
	lock_btn.name = "LockButton"
	lock_btn.text = "LOCK [Enter]"
	lock_btn.focus_mode = Control.FOCUS_NONE
	lock_btn.custom_minimum_size = Vector2(240, 46)
	lock_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	lock_btn.add_theme_font_size_override("font_size", 18)
	lock_btn.add_theme_color_override("font_color", Color(0.3, 0.9, 0.5))
	lock_btn.pressed.connect(lock)
	content.add_child(lock_btn)
	ControllerSupport.focus_buttons(self, true)


func _process(delta: float) -> void:
	super._process(delta)
	if _done:
		return

	_flicker_timer -= delta
	if _flicker_timer <= 0.0:
		_flicker_timer = randf_range(0.3, 0.6)
		_flicker_visible = not _flicker_visible
		if sun_label != null:
			sun_label.visible = _flicker_visible

	if _hold_dir != 0:
		_hold_time += delta
		if _hold_time >= HOLD_INITIAL_DELAY:
			_repeat_timer += delta
			while _repeat_timer >= HOLD_REPEAT_INTERVAL:
				_repeat_timer -= HOLD_REPEAT_INTERVAL
				step_array(_hold_dir)


func _unhandled_input(event: InputEvent) -> void:
	if _done or not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed:
		return

	var keycode := key_event.keycode
	if keycode == KEY_NONE:
		keycode = key_event.physical_keycode

	if keycode == KEY_ENTER or keycode == KEY_KP_ENTER:
		if not key_event.echo:
			var vp := get_viewport()
			if vp != null:
				vp.set_input_as_handled()
			lock()
		return

	if keycode == KEY_A or keycode == KEY_LEFT:
		var vp := get_viewport()
		if vp != null:
			vp.set_input_as_handled()
		step_array(-1)
		return

	if keycode == KEY_D or keycode == KEY_RIGHT:
		var vp := get_viewport()
		if vp != null:
			vp.set_input_as_handled()
		step_array(1)
		return


func _start_hold(dir: int) -> void:
	if _done:
		return
	_hold_dir = dir
	_hold_time = 0.0
	_repeat_timer = 0.0
	step_array(dir)


func _stop_hold() -> void:
	_hold_dir = 0
	_hold_time = 0.0
	_repeat_timer = 0.0


func step_array(step: int) -> void:
	if _done:
		return
	var sfx: Node = get_node_or_null("/root/Sfx")
	if sfx != null and sfx.has_method("play"):
		sfx.play("click")
	set_array(clampi(array_deg + step, 0, 180))


func set_array(deg: int) -> void:
	if _done:
		return
	array_deg = deg
	if array_label != null:
		array_label.text = "ARRAY: %d°" % array_deg


func set_sun_bearing(deg: int) -> void:
	sun_bearing = deg
	if sun_label != null:
		sun_label.text = "SUN BEARING: %d°" % sun_bearing


func lock() -> void:
	if _done:
		return

	var sfx: Node = get_node_or_null("/root/Sfx")
	if sfx != null and sfx.has_method("play"):
		sfx.play("click")

	if abs(array_deg - sun_bearing) <= 5:
		complete()
	else:
		fail("The array locked away from the sun and the batteries drained in the storm.")
