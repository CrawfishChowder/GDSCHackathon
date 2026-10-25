extends SceneTree

## Haptics must survive every signal it listens to with no controller connected.


func _fail(reason: String) -> void:
	paused = false
	print("FAIL: " + reason)
	quit(1)


func _initialize() -> void:
	await process_frame
	var haptics: Node = root.get_node_or_null("Haptics")
	if haptics == null:
		return _fail("Haptics autoload missing")
	var mm: Node = root.get_node("MalfunctionManager")
	if mm.get_signal_connection_list("player_died").filter(func(c: Dictionary) -> bool: return (c["callable"] as Callable).get_object() == haptics).is_empty():
		return _fail("Haptics did not connect to MalfunctionManager.player_died")
	mm.emit_signal("malfunction_started", "o2", "O2", 30.0)
	mm.emit_signal("practice_mistake", "o2", "test")
	mm.emit_signal("malfunction_fixed", "o2")
	mm.emit_signal("player_died", "o2", "O2")
	var stress: Node = root.get_node("Stress")
	stress.set("heart_rate", 150.0)
	await process_frame
	await process_frame
	if float(haptics.get("_beat_timer")) <= 0.0:
		return _fail("heartbeat timer did not start above 120 BPM")
	stress.set("heart_rate", 72.0)
	await process_frame
	haptics.call("pulse", 1.0, 1.0, 0.1)
	print("PASS")
	quit(0)
