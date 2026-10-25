class_name TitleBackground
extends ColorRect

const SHADER_SRC := """shader_type canvas_item;

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
	vec3 sky = mix(vec3(0.85, 0.60, 0.40), vec3(0.92, 0.76, 0.62), clamp(UV.y / 0.55, 0.0, 1.0));
	vec2 sun_delta = (UV - vec2(0.68, 0.22)) * vec2(1.77, 1.0);
	float sun_dist = length(sun_delta);
	float sun = (smoothstep(0.035, 0.025, sun_dist) + smoothstep(0.18, 0.0, sun_dist) * 0.4);
	vec3 col = sky + vec3(1.0, 0.98, 0.92) * sun;

	float x1 = UV.x + TIME * 0.004;
	float d1 = 0.52 + 0.05 * sin(x1 * 6.0 + 1.2) + 0.02 * sin(x1 * 13.0) + 0.02 * fbm(vec2(x1 * 7.0, 1.0));
	col = mix(col, vec3(0.60, 0.30, 0.16), smoothstep(d1, d1 + 0.005, UV.y));

	float x2 = UV.x + TIME * 0.010;
	float d2 = 0.64 + 0.07 * sin(x2 * 4.5 + 3.8) + 0.03 * sin(x2 * 9.0) + 0.03 * fbm(vec2(x2 * 5.0, 5.0));
	col = mix(col, vec3(0.55, 0.25, 0.12), smoothstep(d2, d2 + 0.005, UV.y));

	float x3 = UV.x + TIME * 0.020;
	float d3 = 0.76 + 0.08 * sin(x3 * 3.2 + 0.5) + 0.04 * sin(x3 * 7.5 + 2.0) + 0.03 * fbm(vec2(x3 * 4.0, 9.0));
	col = mix(col, vec3(0.40, 0.18, 0.08), smoothstep(d3, d3 + 0.005, UV.y));

	float faint_dust = fbm((UV * vec2(3.0, 2.0) + vec2(TIME * 0.03, TIME * 0.008)) * 3.0) * 0.15;
	col = mix(col, vec3(0.75, 0.50, 0.30), faint_dust);

	vec2 vig_coord = (UV - vec2(0.5)) * vec2(1.2, 1.0);
	float vig = 1.0 - smoothstep(0.30, 0.85, length(vig_coord));
	col *= mix(0.35, 1.0, vig);

	COLOR = vec4(col, 1.0);
}
"""


func _init() -> void:
	name = "TitleBackground"
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	_setup_shader()


func _setup_shader() -> void:
	var shader := Shader.new()
	shader.code = SHADER_SRC
	var mat := ShaderMaterial.new()
	mat.shader = shader
	material = mat
