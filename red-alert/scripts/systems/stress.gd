# Calculates astronaut stress and heart rate (BPM) from alarms, mistakes, and pacing.
# Listened to by HeartRateOverlay, SFX, and Voice; lowered by holding the breathe key.
extends Node

signal heart_rate_changed(bpm: float)

var heart_rate: float = 72.0
var external_heart_rate: float = -1.0

var _spikes: Array[float] = []
var _current_malfunction: String = ""
var _hint_played_for_malfunction: bool = false
var _emit_timer: float = 0.25
var _last_emitted_bpm: float = -1.0


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	_connect_signals()


func _process(delta: float) -> void:
	_connect_signals()

	var mm: Node = _get_mm()
	var active_malf: String = String(mm.get("active_id")) if mm != null else ""

	if active_malf != _current_malfunction:
		_current_malfunction = active_malf
		_hint_played_for_malfunction = false

	# Target computation
	var target: float = 72.0
	if mm != null and String(mm.get("active_id")) != "":
		if float(mm.get("time_left")) < 15.0:
			target = 125.0
		else:
			target = 95.0

	# Decay practice mistake spikes (each +20 decays linearly over 5 s)
	var spike_bonus: float = 0.0
	var i: int = _spikes.size() - 1
	while i >= 0:
		_spikes[i] -= delta
		if _spikes[i] <= 0.0:
			_spikes.remove_at(i)
		else:
			spike_bonus += 20.0 * (_spikes[i] / 5.0)
		i -= 1
	target += spike_bonus

	if is_breathing():
		target = maxf(65.0, target - 35.0)

	# Heart rate adjustment
	if external_heart_rate >= 0.0:
		heart_rate = external_heart_rate
	else:
		if target > heart_rate:
			heart_rate = move_toward(heart_rate, target, 6.0 * delta)
		elif target < heart_rate:
			var down_rate: float = 8.0 if is_breathing() else 4.0
			heart_rate = move_toward(heart_rate, target, down_rate * delta)
		heart_rate = clampf(heart_rate, 55.0, 170.0)

	# Crew breathing voice line: once per malfunction when crossing 120
	if _current_malfunction != "" and not _hint_played_for_malfunction:
		if heart_rate >= 120.0:
			_hint_played_for_malfunction = true
			var voice: Node = get_node_or_null("/root/Voice")
			if voice != null and voice.has_method("say"):
				voice.say("crew_breathe")

	# Emit signal at most 4 times per second
	_emit_timer += delta
	if _emit_timer >= 0.25:
		_emit_timer = 0.0
		if heart_rate != _last_emitted_bpm:
			_last_emitted_bpm = heart_rate
			heart_rate_changed.emit(heart_rate)


# Returns true if player is holding the designated breathe key (default: B).
func is_breathing() -> bool:
	if InputMap.has_action("breathe"):
		return Input.is_action_pressed("breathe")
	return false


func _connect_signals() -> void:
	var mm: Node = _get_mm()
	if mm != null:
		if mm.has_signal("run_started") and not mm.run_started.is_connected(_on_run_started):
			mm.run_started.connect(_on_run_started)
		if mm.has_signal("practice_mistake") and not mm.practice_mistake.is_connected(_on_practice_mistake):
			mm.practice_mistake.connect(_on_practice_mistake)


func _on_run_started() -> void:
	heart_rate = 72.0
	_spikes.clear()
	_current_malfunction = ""
	_hint_played_for_malfunction = false
	_last_emitted_bpm = 72.0
	_emit_timer = 0.0
	heart_rate_changed.emit(heart_rate)


func _on_practice_mistake(_cause_id: String, _detail: String) -> void:
	_spikes.append(5.0)


func _get_mm() -> Node:
	return get_node_or_null("/root/MalfunctionManager")
