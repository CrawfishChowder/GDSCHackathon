extends Node

# Godot's standard joypad layout maps DualSense face buttons to A/B/X/Y.
func _enter_tree() -> void:
	for axis: int in range(4):
		var action: String = ["move_left", "move_right", "move_forward", "move_back"][axis]
		var motion := InputEventJoypadMotion.new()
		motion.axis = JOY_AXIS_LEFT_X if axis < 2 else JOY_AXIS_LEFT_Y
		motion.axis_value = -1.0 if axis % 2 == 0 else 1.0
		InputMap.action_add_event(action, motion)
	for pair: Array in [["move_forward", JOY_BUTTON_DPAD_UP], ["move_back", JOY_BUTTON_DPAD_DOWN], ["move_left", JOY_BUTTON_DPAD_LEFT], ["move_right", JOY_BUTTON_DPAD_RIGHT], ["jump", JOY_BUTTON_X], ["interact", JOY_BUTTON_A], ["breathe", JOY_BUTTON_Y], ["ui_up", JOY_BUTTON_DPAD_UP], ["ui_down", JOY_BUTTON_DPAD_DOWN], ["ui_left", JOY_BUTTON_DPAD_LEFT], ["ui_right", JOY_BUTTON_DPAD_RIGHT], ["ui_accept", JOY_BUTTON_A], ["ui_cancel", JOY_BUTTON_B]]:
		var button := InputEventJoypadButton.new()
		button.button_index = pair[1]
		InputMap.action_add_event(pair[0], button)
	var trigger := InputEventJoypadMotion.new()
	trigger.axis = JOY_AXIS_TRIGGER_RIGHT
	trigger.axis_value = 1.0
	InputMap.action_add_event("interact", trigger)
	InputMap.add_action("controller_pause")
	var options := InputEventJoypadButton.new()
	options.button_index = JOY_BUTTON_START
	InputMap.action_add_event("controller_pause", options)


func focus_buttons(root: Node, grab_first: bool = false) -> void:
	var first: Control
	var pending: Array[Node] = [root]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		if node is BaseButton or node is HSlider:
			var control := node as Control
			control.focus_mode = Control.FOCUS_ALL
			var style := StyleBoxFlat.new()
			style.bg_color = Color(0.08, 0.18, 0.24, 0.9)
			style.border_color = Color(0.35, 0.9, 1.0)
			style.set_border_width_all(3)
			style.set_corner_radius_all(5)
			control.add_theme_stylebox_override("focus", style)
			if first == null and control.visible and (not node is BaseButton or not (node as BaseButton).disabled):
				first = control
		var children := node.get_children()
		for i in range(children.size() - 1, -1, -1):
			pending.append(children[i])
	if grab_first and first != null:
		first.grab_focus.call_deferred()
