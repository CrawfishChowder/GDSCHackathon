extends SceneTree

var got := {}


func _initialize() -> void:
	await process_frame

	var settings: Node = root.get_node_or_null("Settings")
	if settings == null:
		print("FAIL: Settings autoload not found")
		quit(1)
		return

	if settings.has_signal("settings_changed"):
		settings.connect("settings_changed", func(k: String, v: Variant) -> void:
			got[k] = v
		)

	# 1. Test show_fps
	settings.call("set_setting", "show_fps", true)
	await process_frame

	var fps_label: Label = settings.get("fps_label") as Label
	if fps_label == null:
		fps_label = settings.get_node_or_null("FPSLayer/FPSLabel") as Label

	if fps_label == null:
		print("FAIL: FPS label not found on Settings")
		quit(1)
		return

	if not fps_label.visible:
		print("FAIL: FPS label is not visible after setting show_fps=true")
		quit(1)
		return

	# Reset show_fps
	settings.call("set_setting", "show_fps", false)
	await process_frame

	if fps_label.visible:
		print("FAIL: FPS label is still visible after setting show_fps=false")
		quit(1)
		return

	# 2. Test ui_scale
	settings.call("set_setting", "ui_scale", 1.25)
	await process_frame

	var factor: float = float(root.content_scale_factor)
	if abs(factor - 1.25) > 0.01:
		print("FAIL: root.content_scale_factor %f is not 1.25 (±0.01)" % factor)
		quit(1)
		return

	# Reset ui_scale
	settings.call("set_setting", "ui_scale", 1.0)
	await process_frame

	var reset_factor: float = float(root.content_scale_factor)
	if abs(reset_factor - 1.0) > 0.01:
		print("FAIL: root.content_scale_factor %f is not 1.0 after reset" % reset_factor)
		quit(1)
		return

	# 3. Test F11 input toggle
	var initial_fs: bool = bool(settings.call("get_setting", "fullscreen"))
	var key_ev := InputEventKey.new()
	key_ev.physical_keycode = KEY_F11
	key_ev.pressed = true
	key_ev.echo = false
	settings.call("_unhandled_input", key_ev)
	await process_frame

	var toggled_fs: bool = bool(settings.call("get_setting", "fullscreen"))
	if toggled_fs == initial_fs:
		print("FAIL: F11 did not toggle fullscreen setting")
		quit(1)
		return

	# Toggle back
	settings.call("_unhandled_input", key_ev)
	await process_frame

	var reverted_fs: bool = bool(settings.call("get_setting", "fullscreen"))
	if reverted_fs != initial_fs:
		print("FAIL: F11 did not toggle fullscreen setting back")
		quit(1)
		return

	# 4. Test SettingsPanel instantiation and display settings rows
	var panel_script := load("res://scripts/ui/settings_panel.gd") as GDScript
	if panel_script == null:
		print("FAIL: Failed to load settings_panel.gd")
		quit(1)
		return

	var panel: Control = panel_script.new() as Control
	if panel == null:
		print("FAIL: Failed to instantiate SettingsPanel")
		quit(1)
		return

	root.add_child(panel)
	await process_frame
	panel.queue_free()

	paused = false
	print("PASS")
	quit(0)
