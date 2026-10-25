extends Control

const LOGO_TEXT := "TBD"
const ANIMATION_INTERVAL := 1.0 / 30.0
const COLORS: Array[Color] = [
	Color("ff3b81"),
	Color("27e8ff"),
	Color("ffe044"),
	Color("8cff4a"),
	Color("b96cff"),
	Color("ff7838"),
]

@export var random_seed: int = 2001
@export_range(0.25, 3.0, 0.05) var speed_scale: float = 1.0
@export_range(0, 5, 1) var initial_color_index: int = 0

var _rng := RandomNumberGenerator.new()
var _font: Font
var _logo_position := Vector2.ZERO
var _logo_size := Vector2(180.0, 82.0)
var _velocity := Vector2(115.0, 83.0)
var _safe_margin: float = 16.0
var _color_index: int = 0
var _layout_ready: bool = false
var _animation_accumulator: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	_rng.seed = random_seed
	_font = ThemeDB.fallback_font
	_color_index = posmod(initial_color_index, COLORS.size())
	var direction := Vector2(
		-1.0 if _rng.randi_range(0, 1) == 0 else 1.0,
		-1.0 if _rng.randi_range(0, 1) == 0 else 1.0
	)
	_velocity = Vector2(118.0, 82.0) * direction * speed_scale
	resized.connect(_update_layout.bind(false))
	_update_layout(true)


func _process(delta: float) -> void:
	if not _layout_ready:
		return
	_animation_accumulator += delta
	if _animation_accumulator < ANIMATION_INTERVAL:
		return
	delta = minf(_animation_accumulator, 0.1)
	_animation_accumulator = fmod(_animation_accumulator, ANIMATION_INTERVAL)

	var minimum := Vector2(_safe_margin, _safe_margin)
	var maximum := size - _logo_size - minimum
	var next_position := _logo_position + _velocity * delta

	var x_result := _reflect_axis(
		next_position.x, _velocity.x, minimum.x, maximum.x
	)
	next_position.x = x_result.x
	_velocity.x = x_result.y
	for _bounce_index in int(x_result.z):
		_advance_color()

	var y_result := _reflect_axis(
		next_position.y, _velocity.y, minimum.y, maximum.y
	)
	next_position.y = y_result.x
	_velocity.y = y_result.y
	for _bounce_index in int(y_result.z):
		_advance_color()

	_logo_position = next_position.clamp(minimum, maximum)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color.BLACK)
	if not _layout_ready or _font == null:
		return

	var color := COLORS[_color_index]
	var logo_rect := Rect2(_logo_position, _logo_size)
	draw_rect(logo_rect.grow(8.0), Color(color, 0.12), true)
	draw_rect(logo_rect, Color(0.012, 0.012, 0.025, 1.0), true)
	draw_rect(logo_rect, color, false, 5.0)
	draw_line(
		logo_rect.position + Vector2(12.0, 11.0),
		logo_rect.position + Vector2(logo_rect.size.x - 12.0, 11.0),
		Color(color, 0.65),
		2.0
	)

	var font_size := maxi(18, int(_logo_size.y * 0.54))
	var text_size := _font.get_string_size(
		LOGO_TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size
	)
	var baseline := _logo_position + Vector2(
		(_logo_size.x - text_size.x) * 0.5,
		(_logo_size.y - text_size.y) * 0.5 + _font.get_ascent(font_size)
	)
	draw_string(
		_font,
		baseline + Vector2(3.0, 3.0),
		LOGO_TEXT,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		font_size,
		Color(color, 0.2)
	)
	draw_string(
		_font,
		baseline,
		LOGO_TEXT,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		font_size,
		color
	)


func get_logo_rect() -> Rect2:
	return Rect2(_logo_position, _logo_size)


func get_safe_rect() -> Rect2:
	return Rect2(
		Vector2(_safe_margin, _safe_margin),
		size - Vector2(_safe_margin, _safe_margin) * 2.0
	)


func _update_layout(randomize_position: bool) -> void:
	if size.x < 1.0 or size.y < 1.0:
		return

	_safe_margin = clampf(minf(size.x, size.y) * 0.045, 8.0, 24.0)
	_logo_size = Vector2(
		clampf(size.x * 0.31, 118.0, 220.0),
		clampf(size.y * 0.24, 62.0, 102.0)
	)
	_logo_size.x = minf(_logo_size.x, size.x - _safe_margin * 2.0 - 2.0)
	_logo_size.y = minf(_logo_size.y, size.y - _safe_margin * 2.0 - 2.0)

	var minimum := Vector2(_safe_margin, _safe_margin)
	var maximum := size - _logo_size - minimum
	if randomize_position or not _layout_ready:
		_logo_position = Vector2(
			_rng.randf_range(minimum.x, maximum.x),
			_rng.randf_range(minimum.y, maximum.y)
		)
	else:
		_logo_position = _logo_position.clamp(minimum, maximum)
	_layout_ready = true
	queue_redraw()


func _reflect_axis(
	value: float, velocity: float, minimum: float, maximum: float
) -> Vector3:
	var bounce_count := 0
	while value < minimum or value > maximum:
		if value < minimum:
			value = minimum + (minimum - value)
			velocity = absf(velocity)
		else:
			value = maximum - (value - maximum)
			velocity = -absf(velocity)
		bounce_count += 1
	return Vector3(value, velocity, bounce_count)


func _advance_color() -> void:
	_color_index = (_color_index + 1) % COLORS.size()
