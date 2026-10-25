class_name DemoHelper
extends Node

var _overlay_layer: CanvasLayer = null


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	if _overlay_layer == null:
		_create_overlay()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var key_event := event as InputEventKey
	var code: Key = key_event.physical_keycode if key_event.physical_keycode != KEY_NONE else key_event.keycode
	if handle_key(code):
		var vp := get_viewport()
		if vp != null:
			vp.set_input_as_handled()


func overlay_visible() -> bool:
	return _overlay_layer != null and _overlay_layer.visible


func handle_key(keycode: Key) -> bool:
	var host: Node = get_node_or_null("/root/MinigameHost") if is_inside_tree() else null
	if host != null and host.has_method("is_open") and bool(host.call("is_open")):
		return false

	var mm: Node = get_node_or_null("/root/MalfunctionManager") if is_inside_tree() else null

	match keycode:
		KEY_F4:
			if mm != null and mm.has_method("trigger"):
				mm.call("trigger", "co2")
			return true
		KEY_F5:
			if mm != null and mm.has_method("trigger"):
				mm.call("trigger", "dust_storm")
			return true
		KEY_F6:
			if mm != null:
				var shift_len: float = float(mm.get("SHIFT_LENGTH")) if mm.get("SHIFT_LENGTH") != null else 300.0
				mm.set("survived_seconds", shift_len - 10.0)
			return true
		KEY_F7:
			if mm != null and mm.has_method("kill"):
				mm.call("kill", "reactor", "mistake", "Demo: instant failure.")
			return true
		KEY_F12:
			if _overlay_layer == null:
				_create_overlay()
			if _overlay_layer != null:
				_overlay_layer.visible = not _overlay_layer.visible
			return true
		_:
			return false


func _create_overlay() -> void:
	if _overlay_layer != null:
		return

	_overlay_layer = CanvasLayer.new()
	_overlay_layer.name = "DemoOverlayLayer"
	_overlay_layer.layer = 30
	_overlay_layer.visible = false
	add_child(_overlay_layer)

	var panel := PanelContainer.new()
	panel.name = "DemoKeysPanel"
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.offset_left = -280.0
	panel.offset_top = 16.0
	panel.offset_right = -16.0
	panel.offset_bottom = 250.0
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel.grow_vertical = Control.GROW_DIRECTION_END
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.06, 0.08, 0.92)
	style.set_border_width_all(2)
	style.border_color = Color(0.3, 0.8, 1.0, 0.8)
	style.set_corner_radius_all(6)
	style.content_margin_left = 14.0
	style.content_margin_top = 10.0
	style.content_margin_right = 14.0
	style.content_margin_bottom = 10.0
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.name = "KeyList"
	vbox.add_theme_constant_override("separation", 6)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "DEMO CONTROLS (F12)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(title)

	var key_text := Label.new()
	key_text.text = "F1: Reactor meltdown\nF2: Power failure\nF3: O2 depletion\nF4: CO2 buildup\nF5: Dust storm\nF6: Skip near shift end\nF7: Instant failure\nF12: Toggle demo keys"
	key_text.add_theme_font_size_override("font_size", 13)
	key_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(key_text)

	_overlay_layer.add_child(panel)
