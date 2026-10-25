extends Node

signal event_started(event_id: StringName)
signal event_finished(event_id: StringName, succeeded: bool)

@export var auto_start_event: StringName = &"power_failure"
@export_range(0.0, 30.0, 0.5) var auto_start_delay_seconds: float = 5.0

var _registered_events: Dictionary = {}
var _active_events: Dictionary = {}


func _ready() -> void:
	if str(auto_start_event).is_empty():
		return
	if auto_start_delay_seconds > 0.0:
		await get_tree().create_timer(auto_start_delay_seconds).timeout
	start_event(auto_start_event)


func register_event(event_id: StringName, event_controller: Node) -> void:
	if str(event_id).is_empty() or _registered_events.has(event_id):
		push_warning("Event ID is empty or already registered: %s" % event_id)
		return
	if not event_controller.has_method("start_event"):
		push_warning("Event controller has no start_event method: %s" % event_id)
		return

	_registered_events[event_id] = event_controller
	if event_controller.has_signal("event_finished"):
		event_controller.connect(
			"event_finished", Callable(self, "_on_event_controller_finished")
		)


func start_event(event_id: StringName) -> bool:
	if not _registered_events.has(event_id) or _active_events.has(event_id):
		return false

	var event_controller: Node = _registered_events[event_id]
	_active_events[event_id] = event_controller
	event_started.emit(event_id)
	event_controller.call("start_event")
	return true


func _on_event_controller_finished(event_id: StringName, succeeded: bool) -> void:
	if not _active_events.has(event_id):
		return
	_active_events.erase(event_id)
	event_finished.emit(event_id, succeeded)