extends Node3D

var _monitor: MonitorDisplay
var _status_label: Label
var _update_timer: float = 0.0


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS

	_monitor = MonitorDisplay.new()
	_monitor.name = "MonitorDisplay"
	_monitor.position = Vector3(-2.8, 1.64, 0.285)
	_monitor.rotation = Vector3.ZERO
	add_child(_monitor)

	var content := _monitor.setup(Vector2(1.04, 0.62), Vector2i(384, 224))
	_setup_ui(content)
	_update_status()


func _process(delta: float) -> void:
	_update_timer += delta
	if _update_timer >= 0.25:
		_update_timer = 0.0
		_update_status()


func _setup_ui(root: Control) -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 16)
	root.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var parent_name: String = String(get_parent().name) if get_parent() != null else ""
	var module_name := "MODULE"
	if parent_name.begins_with("North"):
		module_name = "MODULE B: CREW QUARTERS"
	elif parent_name.begins_with("East"):
		module_name = "AIRLOCK"
	elif parent_name.begins_with("West"):
		module_name = "GREENHOUSE"

	var module_label := Label.new()
	module_label.name = "ModuleLabel"
	module_label.text = module_name
	module_label.add_theme_font_size_override("font_size", 22)
	module_label.modulate = Color(0.3, 0.8, 1.0)
	vbox.add_child(module_label)

	_status_label = Label.new()
	_status_label.name = "StatusLabel"
	_status_label.text = "SEALED"
	_status_label.add_theme_font_size_override("font_size", 36)
	_status_label.modulate = Color(1.0, 0.25, 0.2)
	vbox.add_child(_status_label)

	var pressure_label := Label.new()
	pressure_label.name = "PressureLabel"
	pressure_label.text = "PRESSURE NOMINAL"
	pressure_label.add_theme_font_size_override("font_size", 20)
	pressure_label.modulate = Color(0.7, 0.8, 0.9)
	vbox.add_child(pressure_label)


func _update_status() -> void:
	var parent := get_parent()
	var sealed := true
	if parent != null and parent.has_method("is_sealed"):
		sealed = bool(parent.call("is_sealed"))

	if _status_label != null:
		if sealed:
			_status_label.text = "SEALED"
			_status_label.modulate = Color(1.0, 0.25, 0.2)
		else:
			_status_label.text = "OPEN"
			_status_label.modulate = Color(0.2, 0.9, 0.3)
