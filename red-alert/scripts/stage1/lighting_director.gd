# LightingDirector: Controls dynamic ambient lighting, flicker, fog, and hum.
# Dims lights during reactor failures and reduces hum during power outages.
# Reads active malfunction from MalfunctionManager.
class_name LightingDirector
extends Node3D

var _lights: Array[OmniLight3D] = []
var _base_energies: Array[float] = []
var _audio_player: AudioStreamPlayer = null
var _was_power: bool = false


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	_setup_audio()
	_setup_environment()
	var s: Node = get_node_or_null("/root/Settings")
	if s != null and s.has_signal("settings_changed"):
		s.connect("settings_changed", _on_settings_changed)
	var tree := get_tree()
	if tree != null:
		await tree.process_frame
	if not is_inside_tree():
		return
	_collect_room_lights()


func _process(delta: float) -> void:
	var active_id := _get_active_malfunction()
	_update_lights(delta, active_id)
	_update_audio(delta, active_id)


func light_count() -> int:
	return _lights.size()


func average_multiplier() -> float:
	if _lights.is_empty():
		return 0.0
	var sum := 0.0
	var valid_count := 0
	for i in range(_lights.size()):
		var light: OmniLight3D = _lights[i]
		if is_instance_valid(light):
			valid_count += 1
			var base: float = _base_energies[i]
			var ratio := 1.0
			if base > 0.0001:
				ratio = light.light_energy / base
			sum += ratio
	if valid_count > 0:
		return sum / float(valid_count)
	return 0.0


func _get_active_malfunction() -> String:
	var mm: Node = get_node_or_null("/root/MalfunctionManager") if is_inside_tree() else null
	if mm != null and mm.get("active_id") != null:
		return String(mm.get("active_id"))
	return ""


func _collect_room_lights() -> void:
	_lights.clear()
	_base_energies.clear()
	var shell: Node = get_node_or_null("../../Architecture/IndustrialRoomShell")
	if shell != null:
		_search_lights(shell)


func _search_lights(node: Node) -> void:
	for child in node.get_children():
		if child is OmniLight3D and child.name.begins_with("ColdOverheadLight"):
			var omni := child as OmniLight3D
			_lights.append(omni)
			_base_energies.append(omni.light_energy)
		_search_lights(child)


func _update_lights(delta: float, active_id: String) -> void:
	if _lights.is_empty():
		return
	if active_id == "power":
		_was_power = true
		return
	if _was_power:
		_was_power = false
		for i in range(_lights.size()):
			var light: OmniLight3D = _lights[i]
			if is_instance_valid(light):
				light.light_energy = _base_energies[i]

	var target := 1.0
	var is_flicker := false
	if active_id == "reactor" and randf() < 0.25:
		target = 0.4
		is_flicker = true

	var lerp_factor := clampf(1.0 - exp(-8.0 * delta), 0.0, 1.0)
	for i in range(_lights.size()):
		var light: OmniLight3D = _lights[i]
		if is_instance_valid(light):
			var target_energy: float = _base_energies[i] * target
			if is_flicker:
				light.light_energy = target_energy
			else:
				light.light_energy = lerpf(light.light_energy, target_energy, lerp_factor)


func _update_audio(delta: float, active_id: String) -> void:
	if _audio_player == null:
		return
	var factor := clampf(1.0 - exp(-4.0 * delta), 0.0, 1.0)
	var target_pitch := 1.0
	var target_db := -16.0
	if active_id == "power":
		target_pitch = 0.8
		target_db = -24.0
	_audio_player.pitch_scale = lerpf(_audio_player.pitch_scale, target_pitch, factor)
	_audio_player.volume_db = lerpf(_audio_player.volume_db, target_db, factor)


func _setup_audio() -> void:
	var mix_rate := 22050
	var sample_count := 44100
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for i in range(sample_count):
		var t := float(i) / float(mix_rate)
		var fade := clampf(minf(float(i) / 100.0, float(sample_count - 1 - i) / 100.0), 0.0, 1.0)
		var s := 0.06 * sin(TAU * 60.0 * t) + 0.04 * sin(TAU * 120.0 * t) + randf_range(-0.01, 0.01) * fade
		data.encode_s16(i * 2, int(clampi(int(round(s * 32767.0)), -32768, 32767)))

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = sample_count
	wav.data = data

	_audio_player = AudioStreamPlayer.new()
	_audio_player.name = "AmbientHum"
	_audio_player.stream = wav
	_audio_player.volume_db = -16.0
	_audio_player.pitch_scale = 1.0
	_audio_player.process_mode = PROCESS_MODE_ALWAYS
	add_child(_audio_player)
	if DisplayServer.get_name() != "headless":
		_audio_player.play()


func _setup_environment() -> void:
	var we := _get_world_environment()
	if we == null or we.environment == null:
		return
	var env: Environment = we.environment
	var perf: bool = _is_performance_mode()
	env.glow_enabled = not perf
	env.glow_intensity = 0.6
	env.glow_bloom = 0.05
	env.fog_enabled = not perf
	env.fog_light_color = Color(0.05, 0.07, 0.09)
	env.fog_density = 0.008


func _on_settings_changed(key: String, value: Variant) -> void:
	if key == "performance_mode":
		_apply_performance_mode(bool(value))


func _apply_performance_mode(perf: bool) -> void:
	var we := _get_world_environment()
	if we == null or we.environment == null:
		return
	we.environment.glow_enabled = not perf
	we.environment.fog_enabled = not perf


func _is_performance_mode() -> bool:
	var s: Node = get_node_or_null("/root/Settings")
	if s != null and s.has_method("get_setting"):
		var val: Variant = s.get_setting("performance_mode")
		if val != null:
			return bool(val)
	return false


func _get_world_environment() -> WorldEnvironment:
	var we := get_node_or_null("../../WorldEnvironment") as WorldEnvironment
	if we != null:
		return we
	if get_parent() != null:
		we = get_parent().get_node_or_null("WorldEnvironment") as WorldEnvironment
		if we != null:
			return we
	return null
