class_name AlarmController
extends Node3D

const LIGHT_POSITIONS: Array[Vector3] = [
	Vector3(-4.5, 3.0, -3.5),
	Vector3(-4.5, 3.0, 3.5),
	Vector3(4.5, 3.0, -3.5),
	Vector3(4.5, 3.0, 3.5),
]
const LIGHT_COLOR := Color(1.0, 0.08, 0.04)
const LIGHT_RANGE := 7.0

var _lights: Array[OmniLight3D] = []
var _player: AudioStreamPlayer = null
var _alarm_on: bool = false
var _alarm_time: float = 0.0
var _connected: bool = false


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	_setup_lights()
	_setup_audio()
	_connect_malfunction_manager()


func _process(delta: float) -> void:
	if not _connected:
		_connect_malfunction_manager()

	if not _alarm_on:
		return

	_alarm_time += delta
	var energy := 3.0 * (0.5 + 0.5 * sin(_alarm_time * 6.0))
	for light: OmniLight3D in _lights:
		light.light_energy = energy


func start_alarm() -> void:
	_alarm_on = true
	_alarm_time = 0.0
	if _player != null and not _player.playing:
		_player.play()


func stop_alarm() -> void:
	_alarm_on = false
	if _player != null and _player.playing:
		_player.stop()
	for light: OmniLight3D in _lights:
		light.light_energy = 0.0


func is_alarm_on() -> bool:
	return _alarm_on


func _setup_lights() -> void:
	for pos: Vector3 in LIGHT_POSITIONS:
		var light := OmniLight3D.new()
		light.light_color = LIGHT_COLOR
		light.omni_range = LIGHT_RANGE
		light.light_energy = 0.0
		light.position = pos
		add_child(light)
		_lights.append(light)


func _setup_audio() -> void:
	var mix_rate := 22050
	var duration := 1.6
	var sample_count := int(duration * mix_rate)
	var data := PackedByteArray()
	data.resize(sample_count * 2)

	var amp := int(round(32767.0 * 0.35))
	for i: int in range(sample_count):
		var t := float(i) / float(mix_rate)
		var seg := int(t / 0.4)
		var freq := 620.0 if (seg % 2 == 0) else 460.0
		var sample_val := amp if fposmod(t * freq, 1.0) < 0.5 else -amp
		data.encode_s16(i * 2, sample_val)

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = sample_count
	wav.data = data

	_player = AudioStreamPlayer.new()
	_player.stream = wav
	_player.volume_db = -10.0
	_player.process_mode = PROCESS_MODE_ALWAYS
	add_child(_player)


func _connect_malfunction_manager() -> void:
	if _connected:
		return
	var mm := _get_mm()
	if mm != null:
		mm.malfunction_started.connect(_on_malfunction_started)
		mm.malfunction_fixed.connect(_on_malfunction_fixed)
		mm.player_died.connect(_on_player_died)
		_connected = true
		if mm.get("active_id") != "":
			start_alarm()


func _get_mm() -> Node:
	if has_node("/root/MalfunctionManager"):
		return get_node("/root/MalfunctionManager")
	return null


func _on_malfunction_started(_id: String, _display_name: String, _time_limit: float) -> void:
	start_alarm()


func _on_malfunction_fixed(_id: String) -> void:
	stop_alarm()


func _on_player_died(_cause_id: String, _display_name: String) -> void:
	stop_alarm()
