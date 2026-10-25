# MarsWindow: Exterior viewing port showing Mars surface and procedural dust storms.
# Drives custom spatial shader with noise-based terrain and dynamic storm density.
# Reads active malfunction from MalfunctionManager.
class_name MarsWindow
extends Node3D

const SHADER_SRC := """shader_type spatial;
render_mode unshaded;

uniform float storm : hint_range(0.0, 1.0) = 0.0;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 3; i++) {
		v += a * noise(p);
		p *= 2.0;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec3 sky = mix(vec3(0.85, 0.6, 0.4), vec3(0.92, 0.76, 0.62), clamp(UV.y / 0.55, 0.0, 1.0));
	vec2 sun_delta = (UV - vec2(0.68, 0.25)) * vec2(1.636, 1.0);
	float sun_dist = length(sun_delta);
	float sun = (smoothstep(0.035, 0.025, sun_dist) + smoothstep(0.18, 0.0, sun_dist) * 0.4) * (1.0 - storm);
	vec3 col = sky + vec3(1.0, 0.98, 0.92) * sun;

	float d1 = 0.52 + 0.05 * sin(UV.x * 6.0 + 1.2) + 0.02 * sin(UV.x * 13.0) + 0.02 * fbm(vec2(UV.x * 7.0, 1.0));
	col = mix(col, vec3(0.60, 0.30, 0.16), smoothstep(d1, d1 + 0.005, UV.y));
	float d2 = 0.64 + 0.07 * sin(UV.x * 4.5 + 3.8) + 0.03 * sin(UV.x * 9.0) + 0.03 * fbm(vec2(UV.x * 5.0, 5.0));
	col = mix(col, vec3(0.55, 0.25, 0.12), smoothstep(d2, d2 + 0.005, UV.y));
	float d3 = 0.76 + 0.08 * sin(UV.x * 3.2 + 0.5) + 0.04 * sin(UV.x * 7.5 + 2.0) + 0.03 * fbm(vec2(UV.x * 4.0, 9.0));
	col = mix(col, vec3(0.40, 0.18, 0.08), smoothstep(d3, d3 + 0.005, UV.y));

	float faint_dust = fbm((UV * vec2(3.0, 2.0) + vec2(TIME * 0.05, TIME * 0.01)) * 3.0) * 0.15;
	col = mix(col, vec3(0.75, 0.5, 0.3), faint_dust * (1.0 - storm));

	vec2 storm_uv1 = (UV * vec2(4.0, 2.0) + vec2(TIME * 1.6, TIME * 0.2)) * 3.0;
	vec2 storm_uv2 = (UV * vec2(6.0, 3.0) + vec2(TIME * 2.8, -TIME * 0.15)) * 4.0;
	float storm_dust = fbm(storm_uv1) * 0.6 + fbm(storm_uv2) * 0.4;
	vec3 storm_brown = vec3(0.45, 0.3, 0.2);
	col = mix(col, storm_brown, clamp(storm * 0.75 + storm_dust * storm * 0.35, 0.0, 1.0));

	ALBEDO = col;
}
"""

var _storm: float = 0.0
var _mat: ShaderMaterial


func _init() -> void:
	process_mode = PROCESS_MODE_ALWAYS


func _ready() -> void:
	_build_frame()
	_build_quad()
	_build_label()


func _process(delta: float) -> void:
	var mm: Node = get_node_or_null("/root/MalfunctionManager") if is_inside_tree() else null
	var is_dust_storm: bool = false
	if mm != null and mm.get("active_id") != null:
		is_dust_storm = String(mm.get("active_id")) == "dust_storm"
	var target: float = 0.0
	if is_dust_storm:
		target = 1.0
	_storm = lerpf(_storm, target, 1.0 - exp(-2.0 * delta))
	if absf(_storm - target) < 0.002:
		_storm = target
	_storm = clampf(_storm, 0.0, 1.0)
	if _mat != null:
		_mat.set_shader_parameter("storm", _storm)


func storm_level() -> float:
	return _storm


func _build_frame() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.15, 0.18)
	mat.metallic = 0.85
	mat.roughness = 0.4

	var pieces: Array[Dictionary] = [
		{"name": "FrameTop", "size": Vector3(1.96, 0.08, 0.04), "pos": Vector3(0.0, 0.59, 0.0)},
		{"name": "FrameBottom", "size": Vector3(1.96, 0.08, 0.04), "pos": Vector3(0.0, -0.59, 0.0)},
		{"name": "FrameLeft", "size": Vector3(0.08, 1.1, 0.04), "pos": Vector3(-0.94, 0.0, 0.0)},
		{"name": "FrameRight", "size": Vector3(0.08, 1.1, 0.04), "pos": Vector3(0.94, 0.0, 0.0)},
	]
	for p: Dictionary in pieces:
		var mi := MeshInstance3D.new()
		mi.name = p["name"]
		var box := BoxMesh.new()
		box.size = p["size"]
		box.material = mat
		mi.mesh = box
		mi.position = p["pos"]
		add_child(mi)


func _build_quad() -> void:
	var shader := Shader.new()
	shader.code = SHADER_SRC
	_mat = ShaderMaterial.new()
	_mat.shader = shader
	_mat.set_shader_parameter("storm", 0.0)

	var quad := MeshInstance3D.new()
	quad.name = "WindowQuad"
	var qm := QuadMesh.new()
	qm.size = Vector2(1.8, 1.1)
	quad.mesh = qm
	quad.material_override = _mat
	quad.position = Vector3(0.0, 0.0, -0.01)
	add_child(quad)


func _build_label() -> void:
	var label := Label3D.new()
	label.name = "FeedLabel"
	label.text = "MARS · JEZERO REGION · LIVE EXTERIOR FEED"
	label.font_size = 32
	label.pixel_size = 0.003
	label.modulate = Color(0.65, 0.65, 0.65)
	label.position = Vector3(0.0, -0.7, 0.01)
	add_child(label)
