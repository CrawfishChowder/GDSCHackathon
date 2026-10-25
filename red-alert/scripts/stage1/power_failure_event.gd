extends Node

signal event_finished(event_id: StringName, succeeded: bool)

const EVENT_ID: StringName = &"power_failure"

@export_range(0.1, 2.0, 0.05) var flash_interval_seconds: float = 0.45

@onready var _event_director: Node = get_parent()
@onready var _room_shell: Node = get_node_or_null("../../Architecture/IndustrialRoomShell")
@onready var _breaker: Node = get_node_or_null("../../WallFixtures/NorthDoorBreakerBox")
@onready var _world_environment: WorldEnvironment = get_node_or_null("../../WorldEnvironment")

var _is_active: bool = false
var _flash_elapsed: float = 0.0
var _flash_is_on: bool = false
var _has_been_switched_off: bool = false
var _original_ambient_energy: float = 1.4

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	if _event_director != null and _event_director.has_method("register_event"):
		_event_director.call("register_event", EVENT_ID, self)
	if _breaker != null and _breaker.has_signal("main_breaker_changed"):
		_breaker.connect("main_breaker_changed", Callable(self, "_on_main_breaker_changed"))
	var mm: Node = get_node_or_null("/root/MalfunctionManager")
	if mm != null:
		if mm.has_signal("malfunction_started"): mm.connect("malfunction_started", Callable(self, "_on_malfunction_started"))
		if mm.has_signal("malfunction_fixed"): mm.connect("malfunction_fixed", Callable(self, "_on_malfunction_fixed"))
		if mm.has_signal("player_died"): mm.connect("player_died", Callable(self, "_on_player_died"))
		if mm.has_signal("run_started"): mm.connect("run_started", Callable(self, "_on_run_started"))
		if mm.get("active_id") == "power":
			start_event()

func is_active() -> bool:
	return _is_active

func start_event() -> void:
	if _is_active:
		return
	_is_active = true
	_has_been_switched_off = false
	_flash_elapsed = 0.0
	_flash_is_on = true
	if _world_environment != null and _world_environment.environment != null:
		_original_ambient_energy = _world_environment.environment.ambient_light_energy
		_world_environment.environment.ambient_light_energy = 0.2
	if _room_shell != null and _room_shell.has_method("set_alert_lighting"):
		_room_shell.call("set_alert_lighting", true)

func _process(delta: float) -> void:
	if not _is_active:
		return
	_flash_elapsed += delta
	if _flash_elapsed >= flash_interval_seconds:
		_flash_elapsed = fposmod(_flash_elapsed, flash_interval_seconds)
		_flash_is_on = not _flash_is_on
		if _room_shell != null and _room_shell.has_method("set_alert_lighting"):
			_room_shell.call("set_alert_lighting", _flash_is_on)

func _on_main_breaker_changed(is_on: bool) -> void:
	if not _is_active:
		return
	if not is_on:
		_has_been_switched_off = true
	elif _has_been_switched_off:
		var mm: Node = get_node_or_null("/root/MalfunctionManager")
		if mm != null and mm.has_method("fix"):
			mm.call("fix", "power")

func _stop_event(succeeded: bool) -> void:
	if not _is_active:
		return
	_is_active = false
	if _room_shell != null and _room_shell.has_method("restore_overhead_lighting"):
		_room_shell.call("restore_overhead_lighting")
	if _world_environment != null and _world_environment.environment != null:
		_world_environment.environment.ambient_light_energy = _original_ambient_energy
	event_finished.emit(EVENT_ID, succeeded)

func _on_malfunction_started(id: String, _name: String, _limit: float) -> void:
	if id == "power":
		start_event()
func _on_malfunction_fixed(id: String) -> void:
	if id == "power":
		_stop_event(true)
func _on_player_died(_cause: String, _name: String) -> void:
	_stop_event(false)
func _on_run_started() -> void:
	_stop_event(false)
