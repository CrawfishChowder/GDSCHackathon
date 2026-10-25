extends CanvasLayer

const VIGNETTE_SHADER_CODE := """
shader_type canvas_item;

uniform float strength : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float dist = length(uv) * 1.4142;
	float alpha = clamp(dist * dist * 0.45 * strength, 0.0, 0.45);
	COLOR = vec4(0.85, 0.05, 0.05, alpha);
}
"""

var _vignette_rect: ColorRect
var _vignette_mat: ShaderMaterial
var _hr_container: HBoxContainer
var _heart_icon: Label
var _bpm_label: Label
var _breathe_hint: Label
var _pulse_phase: float = 0.0


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	if layer == 1:
		layer = 9

	# Full-screen red vignette
	_vignette_rect = ColorRect.new()
	_vignette_rect.name = "VignetteRect"
	_vignette_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_vignette_mat = ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = VIGNETTE_SHADER_CODE
	_vignette_mat.shader = sh
	_vignette_rect.material = _vignette_mat
	_vignette_rect.visible = false
	add_child(_vignette_rect)

	# Centered hint for breathing when heart rate is elevated
	_breathe_hint = Label.new()
	_breathe_hint.name = "BreatheHint"
	_breathe_hint.text = "Hold B to breathe"
	_breathe_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_breathe_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_breathe_hint.add_theme_font_size_override("font_size", 18)
	_breathe_hint.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
	_breathe_hint.add_theme_constant_override("outline_size", 4)
	_breathe_hint.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
	_breathe_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_breathe_hint.anchor_left = 0.5
	_breathe_hint.anchor_right = 0.5
	_breathe_hint.anchor_top = 0.5
	_breathe_hint.anchor_bottom = 0.5
	_breathe_hint.offset_left = -200.0
	_breathe_hint.offset_right = 200.0
	_breathe_hint.offset_top = 70.0
	_breathe_hint.offset_bottom = 100.0
	_breathe_hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_breathe_hint.visible = false
	add_child(_breathe_hint)

	# Top-left heart rate display below HUD stats (y about 44)
	_hr_container = HBoxContainer.new()
	_hr_container.name = "HeartRateContainer"
	_hr_container.position = Vector2(16.0, 44.0)
	_hr_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hr_container.add_theme_constant_override("separation", 6)
	add_child(_hr_container)

	_heart_icon = Label.new()
	_heart_icon.name = "HeartIcon"
	_heart_icon.text = "♥"
	_heart_icon.add_theme_font_size_override("font_size", 16)
	_heart_icon.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25))
	_heart_icon.custom_minimum_size = Vector2(16, 16)
	_heart_icon.pivot_offset = Vector2(8, 8)
	_hr_container.add_child(_heart_icon)

	_bpm_label = Label.new()
	_bpm_label.name = "BPMLabel"
	_bpm_label.text = "72 BPM"
	_bpm_label.add_theme_font_size_override("font_size", 16)
	_bpm_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	_bpm_label.add_theme_constant_override("outline_size", 4)
	_bpm_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
	_hr_container.add_child(_bpm_label)


func _process(delta: float) -> void:
	var stress := get_node_or_null("/root/Stress")
	var bpm: float = float(stress.get("heart_rate")) if stress != null else 72.0

	# Vignette update
	var s := vignette_strength()
	if _vignette_mat != null:
		_vignette_mat.set_shader_parameter("strength", s)
	if _vignette_rect != null:
		_vignette_rect.visible = (s > 0.001)

	# Pulse scale at current BPM
	_pulse_phase += delta * (bpm / 60.0) * TAU
	if _pulse_phase > TAU:
		_pulse_phase = fmod(_pulse_phase, TAU)
	var pulse_scale := 1.0 + 0.25 * pow(maxf(0.0, sin(_pulse_phase)), 3.0)
	if _heart_icon != null:
		_heart_icon.scale = Vector2(pulse_scale, pulse_scale)

	# Label update with ELEVATED (> 110) or CRITICAL (> 135)
	var status_text := ""
	var text_color := Color(0.85, 0.85, 0.85)
	if bpm > 135.0:
		status_text = "  CRITICAL"
		text_color = Color(1.0, 0.25, 0.25)
	elif bpm > 110.0:
		status_text = "  ELEVATED"
		text_color = Color(1.0, 0.75, 0.2)

	if _bpm_label != null:
		_bpm_label.text = "%d BPM%s" % [int(round(bpm)), status_text]
		_bpm_label.add_theme_color_override("font_color", text_color)

	# Hint visibility
	if _breathe_hint != null:
		_breathe_hint.visible = (bpm > 110.0)


func vignette_strength() -> float:
	var stress := get_node_or_null("/root/Stress")
	var bpm: float = float(stress.get("heart_rate")) if stress != null else 72.0
	var breathing: bool = bool(stress.call("is_breathing")) if stress != null and stress.has_method("is_breathing") else false
	var s: float = clampf((bpm - 110.0) / 50.0, 0.0, 1.0)
	if breathing:
		s *= 0.5
	return s
