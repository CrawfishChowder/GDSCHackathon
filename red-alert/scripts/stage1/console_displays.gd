extends Node

const DISPLAY_KINDS := {
	&"console_left": MonitorDisplay.DisplayKind.ATMOSPHERE,
	&"console_center": MonitorDisplay.DisplayKind.STATUS,
	&"console_right": MonitorDisplay.DisplayKind.POWER,
}

var _display_service: Node
var _display_scenes: Dictionary = {}
var _claimed_monitors: Array[StringName] = []


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	call_deferred("_initialize")


func _initialize() -> void:
	_display_service = get_tree().get_first_node_in_group(&"monitor_display_service")
	if _display_service == null:
		push_warning("Console displays could not find the monitor display service.")
		return
	for monitor_id: StringName in DISPLAY_KINDS:
		_display_scenes[monitor_id] = _make_display_scene(DISPLAY_KINDS[monitor_id])

	var manager := get_node_or_null("/root/MalfunctionManager")
	if manager == null:
		return
	manager.malfunction_started.connect(_on_malfunction_started)
	manager.malfunction_fixed.connect(_on_malfunction_finished)
	manager.player_died.connect(_on_player_died)
	manager.shift_completed.connect(_on_shift_completed)
	manager.run_started.connect(_on_run_started)
	if not String(manager.get("active_id")).is_empty():
		_show_emergency_displays()


func _make_display_scene(kind: MonitorDisplay.DisplayKind) -> PackedScene:
	var display := MonitorDisplay.new()
	display.name = "GameplayStatusDisplay"
	display.display_kind = kind
	var packed := PackedScene.new()
	if packed.pack(display) != OK:
		push_error("Unable to pack gameplay monitor display.")
	display.free()
	return packed


func _show_emergency_displays() -> void:
	_release_emergency_displays()
	for monitor_id: StringName in DISPLAY_KINDS:
		if _display_service.claim_monitor(
			monitor_id, self, _display_scenes[monitor_id]
		):
			_claimed_monitors.append(monitor_id)


func _release_emergency_displays() -> void:
	if not is_instance_valid(_display_service):
		_claimed_monitors.clear()
		return
	for monitor_id in _claimed_monitors:
		_display_service.release_monitor(monitor_id, self)
	_claimed_monitors.clear()


func _on_malfunction_started(
	_id: String, _display_name: String, _time_limit: float
) -> void:
	_show_emergency_displays()


func _on_malfunction_finished(_id: String) -> void:
	_release_emergency_displays()


func _on_player_died(_id: String, _display_name: String) -> void:
	_show_emergency_displays()


func _on_shift_completed() -> void:
	_release_emergency_displays()


func _on_run_started() -> void:
	_release_emergency_displays()
