class_name AlarmController
extends Node3D

const LIGHT_POSITIONS: Array[Vector3] = [
	Vector3(-4.5, 3.0, -3.5), Vector3(-4.5, 3.0, 3.5),
	Vector3(4.5, 3.0, -3.5), Vector3(4.5, 3.0, 3.5),
]
const LIGHT_COLOR := Color(1.0, 0.08, 0.04)
const LIGHT_RANGE := 7.0

const STATION_POSITIONS: Dictionary = {
	"reactor": Vector3(0.0, 1.4, 3.9), "o2": Vector3(-2.13, 1.4, 3.9),
	"co2": Vector3(2.13, 1.4, 3.9), "power": Vector3(2.8, 1.55, -4.6),
	"dust_storm": Vector3(5.6, 1.5, -3.6),
}

var _lights: Array[OmniLight3D] = []
var _player: AudioStreamPlayer = null
var _ping_player: AudioStreamPlayer3D = null
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
	if _player != null and not _player.playing and DisplayServer.get_name() != "headless":
		_player.play()


func stop_alarm() -> void:
	_alarm_on = false
	if _player != null and _player.playing:
		_player.stop()
	for light: OmniLight3D in _lights:
		light.light_energy = 0.0
	_stop_ping()


func is_alarm_on() -> bool:
	return _alarm_on


func _setup_lights() -> void:
	for pos: Vector3 in LIGHT_POSITIONS:
		var light := OmniLight3D.new()
		light.light_color = LIGHT_COLOR; light.omni_range = LIGHT_RANGE
		light.light_energy = 0.0; light.position = pos
		add_child(light); _lights.append(light)


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
	wav.format = AudioStreamWAV.FORMAT_16_BITS; wav.mix_rate = mix_rate; wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD; wav.loop_begin = 0; wav.loop_end = sample_count
	wav.data = data

	_player = AudioStreamPlayer.new()
	_player.stream = wav; _player.bus = "SFX"; _player.volume_db = -14.0
	_player.process_mode = PROCESS_MODE_ALWAYS; add_child(_player)


func _start_ping(id: String) -> void:
	_stop_ping()
	var sfx: Node = get_node_or_null("/root/Sfx")
	var stream: AudioStream = sfx.get_stream("alarm_ping") if sfx != null and sfx.has_method("get_stream") else null
	_ping_player = AudioStreamPlayer3D.new()
	_ping_player.name = "AlarmPingPlayer"; _ping_player.bus = "SFX"
	_ping_player.volume_db = -6.0; _ping_player.process_mode = PROCESS_MODE_ALWAYS
	if stream != null:
		_ping_player.stream = stream
	if STATION_POSITIONS.has(id):
		_ping_player.position = STATION_POSITIONS[id]
	add_child(_ping_player)
	_ping_player.finished.connect(func() -> void:
		if is_instance_valid(_ping_player) and not _ping_player.playing and DisplayServer.get_name() != "headless":
			_ping_player.play()
	)
	if DisplayServer.get_name() != "headless":
		_ping_player.play()


func _stop_ping() -> void:
	if _ping_player != null:
		if is_instance_valid(_ping_player):
			_ping_player.stop(); _ping_player.queue_free()
		_ping_player = null


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
			start_alarm(); _start_ping(String(mm.get("active_id")))


func _get_mm() -> Node:
	return get_node_or_null("/root/MalfunctionManager")

func _on_malfunction_started(id: String, _display_name: String, _time_limit: float) -> void:
	start_alarm(); _start_ping(id)

func _on_malfunction_fixed(_id: String) -> void:
	stop_alarm()

func _on_player_died(_cause_id: String, _display_name: String) -> void:
	stop_alarm()
