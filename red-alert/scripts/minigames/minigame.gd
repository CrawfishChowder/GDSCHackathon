class_name Minigame
extends Control

## Base class for emergency repair minigames.
## Subclasses build their interface inside _ready() using make_panel().

signal completed
signal cancelled
signal failed(reason: String)


func complete() -> void:
	completed.emit()


func cancel() -> void:
	cancelled.emit()


func fail(reason: String) -> void:
	failed.emit(reason)


## Builds the standard centered minigame modal panel.
## Returns a VBoxContainer inside the panel for minigame puzzle content.
func make_panel(title: String) -> VBoxContainer:
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

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.06, 0.08, 0.95)
	style.set_border_width_all(2)
	style.border_color = Color.CYAN
	style.set_corner_radius_all(8)
	style.content_margin_left = 24.0
	style.content_margin_top = 20.0
	style.content_margin_right = 24.0
	style.content_margin_bottom = 20.0
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

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
	hint_label.text = "Esc to close"
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 14)
	hint_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	root_vbox.add_child(hint_label)

	var content := VBoxContainer.new()
	content.name = "Content"
	content.size_flags_horizontal = SIZE_EXPAND_FILL
	content.size_flags_vertical = SIZE_EXPAND_FILL
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 16)
	root_vbox.add_child(content)

	return content
