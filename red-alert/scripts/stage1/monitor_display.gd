class_name MonitorDisplay
extends Node3D

const CRT_SHADER_CODE := """shader_type spatial;
render_mode unshaded;

uniform sampler2D screen_tex;

void fragment() {
	vec2 centered = UV - vec2(0.5);
	vec2 uv = centered * (1.0 + dot(centered, centered) * 0.08) + vec2(0.5);

	float r = texture(screen_tex, uv + vec2(0.0015, 0.0)).r;
	float g = texture(screen_tex, uv).g;
	float b = texture(screen_tex, uv - vec2(0.0015, 0.0)).b;
	vec3 col = vec3(r, g, b);

	col *= 0.85 + 0.15 * sin(UV.y * 900.0);

	float vig = clamp(1.0 - dot(centered, centered) * 1.5, 0.0, 1.0);
	col *= vig;

	col *= 0.97 + 0.03 * sin(TIME * 60.0);

	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		col = vec3(0.0);
	}

	ALBEDO = col * 1.25;
}
"""

var viewport: SubViewport
var mesh_instance: MeshInstance3D
var root_control: Control


func _init() -> void:
	process_mode = PROCESS_MODE_ALWAYS


func setup(size_m: Vector2, resolution: Vector2i) -> Control:
	viewport = SubViewport.new()
	viewport.name = "SubViewport"
	viewport.size = resolution
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	viewport.process_mode = PROCESS_MODE_ALWAYS
	add_child(viewport)

	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0.015, 0.025, 0.045, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	viewport.add_child(bg)

	root_control = Control.new()
	root_control.name = "Content"
	root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	viewport.add_child(root_control)

	var quad := QuadMesh.new()
	quad.size = size_m

	var shader := Shader.new()
	shader.code = CRT_SHADER_CODE

	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("screen_tex", viewport.get_texture())
	quad.material = mat

	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "ScreenMesh"
	mesh_instance.mesh = quad
	mesh_instance.material_override = mat
	add_child(mesh_instance)

	return root_control
