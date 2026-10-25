extends Node
# Haptics: controller rumble (PS5 DualSense or any gamepad) driven by game signals.
# Alarm = short buzz, mistake = sharp jolt, death = long rumble, heart rate above 120 = heartbeat thumps.
# Does nothing when no controller is connected.

const STRESS_BPM: float = 120.0

var _beat_timer: float = 0.0


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	var mm: Node = get_node_or_null("/root/MalfunctionManager")
	if mm == null:
		return
	mm.malfunction_started.connect(func(_id: String, _n: String, _t: float) -> void: pulse(0.3, 0.6, 0.35))
	mm.practice_mistake.connect(func(_id: String, _d: String) -> void: pulse(0.8, 0.8, 0.3))
	mm.player_died.connect(func(_id: String, _n: String) -> void: pulse(1.0, 1.0, 0.9))
	mm.malfunction_fixed.connect(func(_id: String) -> void: pulse(0.0, 0.4, 0.12))


func _process(delta: float) -> void:
	var stress: Node = get_node_or_null("/root/Stress")
	if stress == null:
		return
	var bpm: float = float(stress.get("heart_rate"))
	if bpm <= STRESS_BPM:
		_beat_timer = 0.0
		return
	_beat_timer -= delta
	if _beat_timer <= 0.0:
		_beat_timer = 60.0 / bpm
		pulse(0.5, 0.0, 0.08)


## Rumbles every connected controller. weak/strong are motor strengths from 0 to 1.
func pulse(weak: float, strong: float, seconds: float) -> void:
	for device: int in Input.get_connected_joypads():
		Input.start_joy_vibration(device, weak, strong, seconds)
