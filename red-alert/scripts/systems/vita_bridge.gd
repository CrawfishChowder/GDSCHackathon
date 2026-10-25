extends Node

signal connection_changed(connected: bool)

const PROTOCOL_VERSION := 1
const DEVICE_TIMEOUT_MSEC := 1500
const BUTTON_ACTIONS := {
	"cross": "jump",
	"square": "interact",
	"l": "breathe",
	"r": "interact",
	"start": "ui_cancel",
}
const AXIS_ACTIONS := [
	"move_left", "move_right", "move_forward", "move_back",
	"look_left", "look_right", "look_up", "look_down",
]

@export_range(1024, 65535, 1) var port: int = 27300

var _udp := PacketPeerUDP.new()
var _peer_ip := ""
var _peer_port: int = 0
var _last_packet_msec: int = 0
var _telemetry_elapsed: float = 0.0
var _connected: bool = false
var _remote_button_actions: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var error := _udp.bind(port, "0.0.0.0")
	if error != OK:
		push_error("Vita bridge could not bind UDP port %d: %s" % [port, error_string(error)])


func _process(delta: float) -> void:
	while _udp.get_available_packet_count() > 0:
		_receive_packet()

	if _connected and Time.get_ticks_msec() - _last_packet_msec > DEVICE_TIMEOUT_MSEC:
		_clear_remote_input()
		_set_connected(false)
		_peer_ip = ""
		_peer_port = 0

	if not _connected:
		return
	_telemetry_elapsed += delta
	if _telemetry_elapsed >= 0.25:
		_telemetry_elapsed = 0.0
		_send_telemetry()


func get_telemetry() -> Dictionary:
	var life_support := get_node_or_null("/root/LifeSupport")
	var manager := get_node_or_null("/root/MalfunctionManager")
	var oxygen := _gauge(life_support, "o2", 1.0)
	var co2 := _gauge(life_support, "co2", 0.0)
	var power := _gauge(life_support, "power", 1.0)
	var core_temp := _gauge(life_support, "core_temp", 0.0)
	var active_id := String(manager.get("active_id")) if manager != null else ""
	var alert := ""
	if not active_id.is_empty() and manager.has_method("display_name"):
		alert = String(manager.call("display_name", active_id))
	var shift_left := 300.0
	if manager != null and manager.has_method("shift_time_left"):
		shift_left = float(manager.call("shift_time_left"))

	return {
		"type": "telemetry",
		"protocol": PROTOCOL_VERSION,
		"connected": _connected,
		"ship": {
			"status": "ALERT" if not active_id.is_empty() else "NOMINAL",
			"shift_seconds_left": roundi(shift_left),
			"fixes": int(manager.get("fixes_count")) if manager != null else 0,
			"alert_id": active_id,
			"alert": alert,
			"alert_seconds_left": roundi(float(manager.get("time_left"))) if manager != null else 0,
		},
		"readings": {
			"oxygen_percent": roundi(oxygen * 100.0),
			"co2_scrubber_percent": roundi((1.0 - co2) * 100.0),
			"power_percent": roundi(power * 100.0),
			"core_temperature_percent": roundi(core_temp * 100.0),
			"coolant_temperature_c": 18 + roundi(core_temp * 72.0),
		},
	}


func apply_remote_input(axes: Dictionary, buttons: Array) -> void:
	_set_axis_actions("move_left", "move_right", float(axes.get("left_x", 0.0)))
	_set_axis_actions("move_forward", "move_back", float(axes.get("left_y", 0.0)))
	_set_axis_actions("look_left", "look_right", float(axes.get("right_x", 0.0)))
	_set_axis_actions("look_up", "look_down", float(axes.get("right_y", 0.0)))
	var next_actions: Dictionary = {}
	for button_name: String in BUTTON_ACTIONS:
		if buttons.has(button_name):
			next_actions[BUTTON_ACTIONS[button_name]] = true
	for action: String in _remote_button_actions:
		if not next_actions.has(action):
			_emit_action_event(action, false)
	for action: String in next_actions:
		if not _remote_button_actions.has(action):
			_emit_action_event(action, true)
	_remote_button_actions = next_actions


func _receive_packet() -> void:
	var packet := _udp.get_packet()
	var message: Variant = JSON.parse_string(packet.get_string_from_utf8())
	if not message is Dictionary:
		return
	var packet_type := String(message.get("type", ""))
	if packet_type != "hello" and packet_type != "input":
		return

	_peer_ip = _udp.get_packet_ip()
	_peer_port = _udp.get_packet_port()
	_last_packet_msec = Time.get_ticks_msec()
	_set_connected(true)
	if packet_type == "input":
		var axes: Variant = message.get("axes", {})
		var buttons: Variant = message.get("buttons", [])
		if axes is Dictionary and buttons is Array:
			apply_remote_input(axes, buttons)
	_send_telemetry()


func _send_telemetry() -> void:
	if _peer_ip.is_empty() or _peer_port <= 0:
		return
	_udp.set_dest_address(_peer_ip, _peer_port)
	_udp.put_packet(JSON.stringify(get_telemetry()).to_utf8_buffer())


func _set_axis_actions(negative_action: String, positive_action: String, value: float) -> void:
	var clamped := clampf(value, -1.0, 1.0)
	_set_action_strength(negative_action, maxf(-clamped, 0.0))
	_set_action_strength(positive_action, maxf(clamped, 0.0))


func _set_action_strength(action: String, strength: float) -> void:
	if strength > 0.05:
		Input.action_press(action, strength)
	else:
		Input.action_release(action)


func _clear_remote_input() -> void:
	for action: String in AXIS_ACTIONS:
		Input.action_release(action)
	for action: String in _remote_button_actions:
		_emit_action_event(action, false)
	_remote_button_actions.clear()


func _emit_action_event(action: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	event.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(event)


func _set_connected(value: bool) -> void:
	if _connected == value:
		return
	_connected = value
	connection_changed.emit(value)


func _gauge(source: Node, gauge: String, fallback: float) -> float:
	if source != null and source.has_method("get_level"):
		return float(source.call("get_level", gauge))
	return fallback