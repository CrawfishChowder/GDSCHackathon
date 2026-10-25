extends Node

signal event_finished(event_id: StringName, succeeded: bool)

const EVENT_ID: StringName = &"power_failure"

@export_range(5.0, 180.0, 1.0) var duration_seconds: float = 60.0
@export_range(0.1, 2.0, 0.05) var flash_interval_seconds: float = 0.45

@onready var _event_director: Node = get_parent()
@onready var _room_shell: Node = get_node("../../Architecture/IndustrialRoomShell")
@onready var _breaker: Node = get_node("../../WallFixtures/NorthDoorBreakerBox")
@onready var _player: Node = get_node("../../FirstPersonPlayer")
@onready var _world_environment: WorldEnvironment = get_node("../../WorldEnvironment")
@onready var _screen_labels: Array[Label3D] = [
	get_node("../../MainConsole/LeftStation/LeftEventScreen"),
	get_node("../../MainConsole/CenterStation/CenterEventScreen"),
	get_node("../../MainConsole/RightStation/RightEventScreen"),
]

var _is_active: bool = false
var _time_remaining: float = 0.0
var _flash_elapsed: float = 0.0
var _flash_is_on: bool = false
var _has_been_switched_off: bool = false
var _original_ambient_energy: float = 1.4


func _ready() -> void:
	_event_director.call("register_event", EVENT_ID, self)
	_breaker.connect(
		"main_breaker_changed", Callable(self, "_on_main_breaker_changed")
	)


func start_event() -> void:
	if _is_active:
		return

	_is_active = true
	_time_remaining = duration_seconds
	_flash_elapsed = 0.0
	_flash_is_on = true
	_has_been_switched_off = false
	_original_ambient_energy = _world_environment.environment.ambient_light_energy
	_world_environment.environment.ambient_light_energy = 0.2
	_room_shell.call("set_alert_lighting", true)
	_update_screen_labels()
	for label in _screen_labels:
		label.show()


func _process(delta: float) -> void:
	if not _is_active:
		return

	_time_remaining -= delta
	_update_screen_labels()
	if _time_remaining <= 0.0:
		_finish_event(false)
		return

	_flash_elapsed += delta
	if _flash_elapsed >= flash_interval_seconds:
		_flash_elapsed = fposmod(_flash_elapsed, flash_interval_seconds)
		_flash_is_on = not _flash_is_on
		_room_shell.call("set_alert_lighting", _flash_is_on)


func _on_main_breaker_changed(is_on: bool) -> void:
	if not _is_active:
		return
	if not is_on:
		_has_been_switched_off = true
	elif _has_been_switched_off:
		_finish_event(true)


func _update_screen_labels() -> void:
	var seconds_left := maxi(0, ceili(_time_remaining))
	var screen_text := "POWER OUT,\nBREAKER MALFUNCTION\n\n%02d SECONDS" % seconds_left
	for label in _screen_labels:
		label.text = screen_text


func _finish_event(succeeded: bool) -> void:
	if not _is_active:
		return

	_is_active = false
	_room_shell.call("restore_overhead_lighting")
	_world_environment.environment.ambient_light_energy = _original_ambient_energy
	for label in _screen_labels:
		label.hide()
		label.text = ""
	if not succeeded:
		_player.call("die")
	event_finished.emit(EVENT_ID, succeeded)