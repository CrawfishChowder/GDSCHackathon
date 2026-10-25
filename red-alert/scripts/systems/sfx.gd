extends Node

const IDS := ["click", "beep", "beep_error", "success", "fail", "clunk", "creak",
	"hiss", "step", "static", "heartbeat", "flatline", "alarm_ping", "hum", "siren"]

var _streams: Dictionary = {}
var _step_streams: Array[AudioStream] = []
var _pool: Array[AudioStreamPlayer] = []
var _pool_idx: int = 0
var _heartbeat_timer: float = 0.0
var _step_timer: float = 0.0

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS; _setup_buses()
	for i in range(8):
		var p := AudioStreamPlayer.new(); p.process_mode = PROCESS_MODE_ALWAYS
		add_child(p); _pool.append(p)
	_setup_streams()

func _process(delta: float) -> void:
	var stress := get_node_or_null("/root/Stress")
	if stress != null and float(stress.get("heart_rate")) > 95.0:
		var bpm := float(stress.get("heart_rate"))
		_heartbeat_timer -= delta
		if _heartbeat_timer <= 0.0:
			play("heartbeat", null, lerpf(-24.0, -6.0, clampf((bpm - 95.0) / 60.0, 0.0, 1.0)), "SFX")
			_heartbeat_timer = 60.0 / bpm
	else: _heartbeat_timer = 0.0

	var p: Node = get_tree().current_scene.get_node_or_null("FirstPersonPlayer") if (get_tree() and get_tree().current_scene) else null
	var on_floor := bool(p.call("is_on_floor")) if (p != null and p.has_method("is_on_floor")) else false
	var vel: Vector3 = p.get("velocity") if (p != null and p.get("velocity") != null) else Vector3.ZERO
	if on_floor and Vector2(vel.x, vel.z).length() > 1.0:
		_step_timer -= delta
		if _step_timer <= 0.0:
			play("step", null, -10.0, "SFX"); _step_timer = 0.42
	else: _step_timer = 0.0

func play(id: String, at: Variant = null, volume_db: float = 0.0, bus: String = "SFX") -> Node:
	if not IDS.has(id): return null
	var stream: AudioStream = _step_streams.pick_random() if (id == "step" and not _step_streams.is_empty()) else get_stream(id)
	if stream == null: return null
	if at is Vector3:
		var p3d := AudioStreamPlayer3D.new()
		p3d.process_mode = PROCESS_MODE_ALWAYS; p3d.stream = stream; p3d.volume_db = volume_db
		p3d.bus = bus; p3d.unit_size = 6.0; p3d.max_distance = 25.0; p3d.finished.connect(p3d.queue_free)
		var par: Node = get_tree().current_scene if (get_tree() != null and get_tree().current_scene != null) else self
		par.add_child(p3d); p3d.global_position = at
		if DisplayServer.get_name() != "headless": p3d.play()
		return p3d
	var p2d: AudioStreamPlayer = null
	for p in _pool:
		if not p.playing: p2d = p; break
	if p2d == null and not _pool.is_empty():
		p2d = _pool[_pool_idx]; _pool_idx = (_pool_idx + 1) % _pool.size()
	if p2d != null:
		p2d.stream = stream; p2d.volume_db = volume_db; p2d.bus = bus
		if DisplayServer.get_name() != "headless": p2d.play()
	return p2d

func get_stream(id: String) -> AudioStream:
	return _streams.get(id, null)

func _setup_buses() -> void:
	if AudioServer.get_bus_index("SFX") == -1:
		var i := _add_bus_named("SFX")
		var rev := AudioEffectReverb.new(); rev.room_size = 0.35; rev.wet = 0.12; AudioServer.add_bus_effect(i, rev)
	if AudioServer.get_bus_index("Voice") == -1: _add_bus_named("Voice")
	if AudioServer.get_bus_index("Radio") == -1:
		var i := _add_bus_named("Radio")
		var bpf := AudioEffectBandPassFilter.new(); bpf.cutoff_hz = 1800.0; AudioServer.add_bus_effect(i, bpf)
		var dst := AudioEffectDistortion.new(); dst.mode = AudioEffectDistortion.MODE_OVERDRIVE
		dst.drive = 0.15; dst.post_gain = -4.0; AudioServer.add_bus_effect(i, dst)

func _add_bus_named(bname: String) -> int:
	AudioServer.add_bus(); var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, bname); AudioServer.set_bus_send(idx, "Master"); return idx

func _setup_streams() -> void:
	for id in ["step_1", "step_2", "step_3", "step"]:
		var p := "res://assets/sfx/%s.ogg" % id
		if ResourceLoader.exists(p):
			var s := load(p) as AudioStream
			if s != null:
				if id == "step": _streams["step"] = s
				else: _step_streams.append(s)
	if _step_streams.is_empty():
		_step_streams = [_gen_blip(280.0, 0.05), _gen_blip(320.0, 0.05), _gen_blip(360.0, 0.05)]
	if not _streams.has("step"): _streams["step"] = _step_streams[0]
	for id in IDS:
		if _streams.has(id): continue
		var p := "res://assets/sfx/%s.ogg" % id
		if ResourceLoader.exists(p):
			var s := load(p) as AudioStream
			if s != null: _streams[id] = s; continue
		match id:
			"static": _streams[id] = _gen_static()
			"heartbeat": _streams[id] = _gen_heartbeat()
			"flatline": _streams[id] = _gen_flatline()
			"fail": _streams[id] = _gen_fail()
			_: _streams[id] = _gen_blip(880.0, 0.08)

func _make_wav(data: PackedByteArray) -> AudioStreamWAV:
	var w := AudioStreamWAV.new(); w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = 22050; w.stereo = false; w.data = data; return w

func _gen_static() -> AudioStreamWAV:
	var n := int(0.4 * 22050.0); var d := PackedByteArray(); d.resize(n * 2); var f := 0.0
	for i in range(n):
		f += 0.2 * (randf_range(-1.0, 1.0) - f)
		d.encode_s16(i * 2, int(clampf(f * 24000.0, -32767.0, 32767.0)))
	return _make_wav(d)

func _gen_heartbeat() -> AudioStreamWAV:
	var n := int(0.5 * 22050.0); var d := PackedByteArray(); d.resize(n * 2)
	for i in range(n):
		var t := float(i) / 22050.0; var env := 0.0
		if t >= 0.04 and t <= 0.16: env = sin((t - 0.04) / 0.12 * PI) * 0.9
		elif t >= 0.22 and t <= 0.32: env = sin((t - 0.22) / 0.10 * PI) * 0.7
		d.encode_s16(i * 2, int(clampf(sin(TAU * 60.0 * t) * env * 30000.0, -32767.0, 32767.0)))
	return _make_wav(d)

func _gen_flatline() -> AudioStreamWAV:
	var n := int(3.0 * 22050.0); var d := PackedByteArray(); d.resize(n * 2)
	for i in range(n):
		var t := float(i) / 22050.0; var env := minf(t / 0.02, minf((3.0 - t) / 0.02, 1.0))
		d.encode_s16(i * 2, int(clampf(sin(TAU * 1000.0 * t) * env * 24000.0, -32767.0, 32767.0)))
	return _make_wav(d)

func _gen_fail() -> AudioStreamWAV:
	var n := int(0.6 * 22050.0); var d := PackedByteArray(); d.resize(n * 2); var ph := 0.0
	for i in range(n):
		var t := float(i) / 22050.0; ph += lerpf(400.0, 100.0, t / 0.6) / 22050.0
		var saw := 2.0 * fposmod(ph, 1.0) - 1.0
		d.encode_s16(i * 2, int(clampf(saw * (1.0 - t / 0.6) * 20000.0, -32767.0, 32767.0)))
	return _make_wav(d)

func _gen_blip(freq: float, dur: float) -> AudioStreamWAV:
	var n := int(dur * 22050.0); var d := PackedByteArray(); d.resize(n * 2)
	for i in range(n):
		var t := float(i) / 22050.0
		d.encode_s16(i * 2, int(clampf(sin(TAU * freq * t) * exp(-t * 35.0) * 24000.0, -32767.0, 32767.0)))
	return _make_wav(d)
