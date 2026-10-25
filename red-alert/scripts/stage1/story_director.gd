extends Node

const BEAT_TIMES: Array[float] = [20.0, 70.0, 120.0, 165.0, 215.0, 270.0]

var manager: Node = null
var _current_beat: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var mm := _get_manager()
	if mm != null and mm.has_signal("run_started"):
		if not mm.run_started.is_connected(_on_run_started):
			mm.run_started.connect(_on_run_started)


func next_beat_index() -> int:
	return _current_beat


func _process(_delta: float) -> void:
	if _current_beat >= BEAT_TIMES.size():
		return
	var mm := _get_manager()
	if mm == null or not bool(mm.get("running")):
		return
	var active_id: String = String(mm.get("active_id"))
	if not active_id.is_empty():
		return
	var survived: float = float(mm.get("survived_seconds"))
	if survived >= BEAT_TIMES[_current_beat]:
		var beat: int = _current_beat
		_current_beat += 1
		_fire_beat(beat, mm)


func _fire_beat(beat_idx: int, mm: Node) -> void:
	match beat_idx:
		0:
			mm.call("trigger", "o2")
			_say("story_o2")
		1:
			_say("story_flare")
			mm.call("trigger", "power")
		2:
			mm.call("trigger", "co2")
			_say("story_co2")
		3:
			mm.call("trigger", "dust_storm")
			_say("story_dust")
		4:
			mm.call("trigger", "reactor")
			var tl: float = float(mm.get("time_left"))
			mm.set("time_left", tl * 0.8)
			_say("story_reactor")
		5:
			_say("story_approach")


func _say(line_id: String) -> void:
	var voice: Node = get_node_or_null("/root/Voice") if is_inside_tree() else null
	if voice != null and voice.has_method("say"):
		voice.call("say", line_id)


func _on_run_started() -> void:
	_current_beat = 0


func _get_manager() -> Node:
	if manager != null and is_instance_valid(manager):
		return manager
	if is_inside_tree():
		var mm := get_node_or_null("/root/MalfunctionManager")
		if mm != null:
			return mm
		if get_tree() != null and get_tree().root != null:
			for child in get_tree().root.get_children():
				if child != self and child.has_method("trigger") and child.has_signal("malfunction_started"):
					return child
	return null
