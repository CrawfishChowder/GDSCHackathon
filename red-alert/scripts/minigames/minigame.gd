class_name Minigame
extends Control

## Base modal interface for all interactive repair minigames.
## Emits completed, cancelled, or failed signals routed by MinigameHost.
## Provides the standard styled modal frame, instructions, and stress screen shake.

signal completed
signal cancelled
signal failed(reason: String)

var _done: bool = false
var _panel: PanelContainer = null
var _base_l: float = -320.0
var _base_t: float = -210.0
var _base_r: float = 320.0
var _base_b: float = 210.0
var _base_captured: bool = false

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS

## Jitters the panel position when the player's heart rate climbs above 120 BPM.
func _process(_delta: float) -> void:
	if _panel == null:
		_panel = get_node_or_null("MinigamePanel") as PanelContainer
		if _panel != null and not _base_captured:
			_base_l = _panel.offset_left
			_base_t = _panel.offset_top
			_base_r = _panel.offset_right
			_base_b = _panel.offset_bottom
			_base_captured = true
	if _panel == null:
		return

	var stress: Node = get_node_or_null("/root/Stress")
	var bpm: float = 0.0
	if stress != null:
		bpm = float(stress.get("heart_rate"))
	var ox: float = 0.0
	var oy: float = 0.0
	if bpm > 120.0:
		var max_offset: float = (bpm - 120.0) / 8.0
		ox = randf_range(-max_offset, max_offset)
		oy = randf_range(-max_offset, max_offset)
	_panel.offset_left = _base_l + ox
	_panel.offset_right = _base_r + ox
	_panel.offset_top = _base_t + oy
	_panel.offset_bottom = _base_b + oy

func is_done() -> bool:
	return _done

func complete() -> void:
	if not _done:
		_done = true
		completed.emit()

func cancel() -> void:
	if not _done:
		_done = true
		cancelled.emit()

func fail(reason: String) -> void:
	if not _done:
		_done = true
		failed.emit(reason)

func add_instruction(content: VBoxContainer, text: String) -> void:
	if content == null:
		return
	var label := Label.new()
	label.name = "InstructionLabel"
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(1.0, 0.75, 0.2))
	content.add_child(label)
	content.move_child(label, 0)

## Builds the standard centered minigame modal panel.
## Returns a VBoxContainer inside the panel for minigame puzzle content.
func make_panel(title: String) -> VBoxContainer:
	process_mode = PROCESS_MODE_ALWAYS
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP

	var panel := PanelContainer.new()
	panel.name = "MinigamePanel"
	panel.custom_minimum_size = Vector2(640, 420)
	panel.set_anchors_preset(PRESET_CENTER)
	panel.offset_left = -320.0
	panel.offset_top = -210.0
	panel.offset_right = 320.0
	panel.offset_bottom = 210.0
	panel.grow_horizontal = GROW_DIRECTION_BOTH
	panel.grow_vertical = GROW_DIRECTION_BOTH
	_panel = panel
	_base_l = panel.offset_left
	_base_t = panel.offset_top
	_base_r = panel.offset_right
	_base_b = panel.offset_bottom
	_base_captured = true

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.06, 0.08, 0.95)
	style.set_border_width_all(2)
	style.border_color = Color.CYAN
	style.set_corner_radius_all(8)
	style.set_content_margin_all(20.0)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	panel.scale = Vector2(0.92, 0.92)
	panel.modulate.a = 0.0
	panel.pivot_offset = panel.custom_minimum_size * 0.5
	_set_panel_pivot.call_deferred(panel)
	_start_panel_tween(panel)

	var root_vbox := VBoxContainer.new()
	root_vbox.name = "RootVBox"
	root_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	root_vbox.size_flags_vertical = SIZE_EXPAND_FILL
	root_vbox.add_theme_constant_override("separation", 8)
	panel.add_child(root_vbox)

	var title_label := Label.new()
	title_label.name = "TitleLabel"
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 26)
	root_vbox.add_child(title_label)

	var hint_label := Label.new()
	hint_label.name = "HintLabel"
	hint_label.text = "Esc to close · keyboard shortcuts shown in [brackets]"
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 14)
	hint_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	root_vbox.add_child(hint_label)

	var content := VBoxContainer.new()
	content.name = "Content"
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.size_flags_horizontal = SIZE_EXPAND_FILL
	content.size_flags_vertical = SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 16)
	root_vbox.add_child(content)
	return content

func _start_panel_tween(panel: PanelContainer) -> void:
	if not is_inside_tree():
		tree_entered.connect(func() -> void: _start_panel_tween(panel), CONNECT_ONE_SHOT)
		return
	if is_instance_valid(panel):
		var tween := create_tween()
		if tween != null:
			tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tween.parallel().tween_property(panel, "scale", Vector2.ONE, 0.18)
			tween.parallel().tween_property(panel, "modulate:a", 1.0, 0.18)

func _set_panel_pivot(panel: PanelContainer) -> void:
	if is_instance_valid(panel):
		panel.pivot_offset = panel.size * 0.5
