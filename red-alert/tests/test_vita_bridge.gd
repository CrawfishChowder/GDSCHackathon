extends SceneTree

class ActionProbe extends Node:
	var interact_pressed := false
	var interact_released := false

	func _unhandled_input(event: InputEvent) -> void:
		if event is InputEventAction and event.action == "interact":
			if event.pressed:
				interact_pressed = true
			else:
				interact_released = true


func _initialize() -> void:
	await process_frame
	var bridge := root.get_node_or_null("VitaBridge")
	if bridge == null:
		_fail("VitaBridge autoload is missing")
		return

	var telemetry: Dictionary = bridge.call("get_telemetry")
	if telemetry.get("type") != "telemetry" or telemetry.get("protocol") != 1:
		_fail("Telemetry packet does not identify the protocol")
		return
	var readings: Dictionary = telemetry.get("readings", {})
	for reading in ["oxygen_percent", "co2_scrubber_percent", "power_percent", "coolant_temperature_c"]:
		if not readings.has(reading):
			_fail("Telemetry is missing %s" % reading)
			return

	var probe := ActionProbe.new()
	root.add_child(probe)
	var client := PacketPeerUDP.new()
	var bind_error := client.bind(0, "127.0.0.1")
	if bind_error != OK:
		_fail("Could not bind UDP test client: %s" % error_string(bind_error))
		return
	client.set_dest_address("127.0.0.1", int(bridge.get("port")))
	if not _send_packet(client, {"type": "hello", "protocol": 1}):
		_fail("Could not send UDP hello")
		return
	var hello_reply := await _read_packet(client)
	if hello_reply.get("type") != "telemetry" or not hello_reply.get("connected", false):
		_fail("UDP hello did not receive connected telemetry")
		return

	if not _send_packet(client, {
		"type": "input",
		"axes": {"left_x": 1.0, "right_y": -1.0},
		"buttons": ["cross", "square", "l", "r", "start"],
	}):
		_fail("Could not send UDP input")
		return
	await _read_packet(client)
	await process_frame
	for action in ["move_right", "look_up", "jump", "interact", "breathe", "ui_cancel"]:
		if not Input.is_action_pressed(action):
			_fail("Remote input did not press %s" % action)
			return
	if not probe.interact_pressed:
		_fail("Remote interact did not reach _unhandled_input")
		return
	if not _send_packet(client, {"type": "input", "axes": {}, "buttons": ["r"]}):
		_fail("Could not send R-shoulder input")
		return
	await _read_packet(client)
	await process_frame
	if not Input.is_action_pressed("interact") or probe.interact_released:
		_fail("Releasing Square also released interact while R remained held")
		return

	if not _send_packet(client, {"type": "input", "axes": {}, "buttons": []}):
		_fail("Could not send UDP input release")
		return
	await _read_packet(client)
	await process_frame
	for action in ["move_right", "look_up", "jump", "interact", "breathe", "ui_cancel"]:
		if Input.is_action_pressed(action):
			_fail("Remote input did not release %s" % action)
			return
	if not probe.interact_released:
		_fail("Remote interact release did not reach _unhandled_input")
		return

	if not _send_packet(client, {"type": "input", "axes": {"left_x": -1.0}, "buttons": ["cross"]}):
		_fail("Could not send held input before disconnect")
		return
	await _read_packet(client)
	bridge.set("_last_packet_msec", Time.get_ticks_msec() - 2000)
	await process_frame
	if bridge.get("_connected") or Input.is_action_pressed("move_left") or Input.is_action_pressed("jump"):
		_fail("Disconnect timeout did not clear remote input")
		return
	client.close()

	print("PASS")
	quit(0)


func _send_packet(client: PacketPeerUDP, message: Dictionary) -> bool:
	return client.put_packet(JSON.stringify(message).to_utf8_buffer()) == OK


func _read_packet(client: PacketPeerUDP) -> Dictionary:
	for _attempt in 60:
		if client.get_available_packet_count() > 0:
			var message: Variant = JSON.parse_string(client.get_packet().get_string_from_utf8())
			return message if message is Dictionary else {}
		await process_frame
	return {}


func _fail(message: String) -> void:
	print("FAIL: %s" % message)
	quit(1)