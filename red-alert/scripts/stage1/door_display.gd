extends Node3D

const DOOR_MONITORS := {
	"North": {
		"id": &"door_north",
		"module": "MODULE B: CREW QUARTERS",
	},
	"East": {
		"id": &"door_east",
		"module": "AIRLOCK",
	},
	"West": {
		"id": &"door_west",
		"module": "GREENHOUSE",
	},
}

var _display_service: Node
var _monitor_id: StringName
var _module_name: String
var _door_open: bool = false
var _claimed: bool = false


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	call_deferred("_initialize")


func _initialize() -> void:
	_display_service = get_tree().get_first_node_in_group(&"monitor_display_service")
	if _display_service == null:
		push_warning("Door display could not find the monitor display service.")
		return
	if not _configure_for_parent():
		push_warning("Door display is attached to an unknown bulkhead door.")
		return

	var door := get_parent()
	_door_open = door.has_method("is_sealed") and not bool(door.call("is_sealed"))
	if door.has_signal("opened"):
		door.opened.connect(_on_door_opened)

	var manager := get_node_or_null("/root/MalfunctionManager")
	if manager == null:
		return
	manager.malfunction_started.connect(_on_malfunction_started)
	manager.malfunction_fixed.connect(_on_malfunction_finished)
	manager.player_died.connect(_on_player_died)
	manager.shift_completed.connect(_on_shift_completed)
	manager.run_started.connect(_on_run_started)
	if not String(manager.get("active_id")).is_empty() or _door_open:
		_show_status()


func _configure_for_parent() -> bool:
	var parent_name := String(get_parent().name)
	for prefix: String in DOOR_MONITORS:
		if parent_name.begins_with(prefix):
			var definition: Dictionary = DOOR_MONITORS[prefix]
			_monitor_id = definition["id"]
			_module_name = definition["module"]
			return true
	return false


func _make_display_scene() -> PackedScene:
	var display := MonitorDisplay.new()
	display.name = "DoorStatusDisplay"
	display.display_kind = MonitorDisplay.DisplayKind.DOOR
	display.module_name = _module_name
	display.door_state = "OPEN" if _door_open else "SEALED"
	var packed := PackedScene.new()
	if packed.pack(display) != OK:
		push_error("Unable to pack door monitor display.")
	display.free()
	return packed


func _show_status() -> void:
	if not is_instance_valid(_display_service):
		return
	if _claimed:
		_display_service.release_monitor(_monitor_id, self)
		_claimed = false
	_claimed = _display_service.claim_monitor(
		_monitor_id, self, _make_display_scene()
	)


func _release_status() -> void:
	if _claimed and is_instance_valid(_display_service):
		_display_service.release_monitor(_monitor_id, self)
	_claimed = false


func _on_door_opened() -> void:
	_door_open = true
	_show_status()


func _on_malfunction_started(
	_id: String, _display_name: String, _time_limit: float
) -> void:
	_show_status()


func _on_malfunction_finished(_id: String) -> void:
	if _door_open:
		_show_status()
	else:
		_release_status()


func _on_player_died(_id: String, _display_name: String) -> void:
	_show_status()


func _on_shift_completed() -> void:
	_release_if_sealed()


func _on_run_started() -> void:
	_release_if_sealed()


func _release_if_sealed() -> void:
	if _door_open:
		_show_status()
	else:
		_release_status()
