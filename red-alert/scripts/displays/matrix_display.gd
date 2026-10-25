extends Control

const CHARACTERS := "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#$%&*+-=<>?/{}[]"

@export var random_seed: int = 1001
@export_range(0.25, 3.0, 0.05) var speed_scale: float = 1.0

var _rng := RandomNumberGenerator.new()
var _columns: Array[Dictionary] = []
var _cell_size: float = 18.0
var _font: Font


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	_rng.seed = random_seed
	_font = ThemeDB.fallback_font
	resized.connect(_rebuild_columns)
	_rebuild_columns()


func _process(delta: float) -> void:
	if _columns.is_empty():
		return

	for column in _columns:
		column["head_y"] += column["speed"] * delta
		column["change_timer"] -= delta
		if column["change_timer"] <= 0.0:
			var glyphs: PackedStringArray = column["glyphs"]
			glyphs[_rng.randi_range(0, glyphs.size() - 1)] = _random_character()
			column["glyphs"] = glyphs
			column["change_timer"] = _rng.randf_range(0.035, 0.16)

		var trail_length: int = column["trail_length"]
		if column["head_y"] - trail_length * _cell_size > size.y:
			_reset_column(column, true)

	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color.BLACK)
	if _font == null:
		return

	var font_size := maxi(10, int(_cell_size * 0.9))
	for column_index in _columns.size():
		var column: Dictionary = _columns[column_index]
		var glyphs: PackedStringArray = column["glyphs"]
		var trail_length: int = column["trail_length"]
		var x := column_index * _cell_size + _cell_size * 0.12
		for trail_index in trail_length:
			var y: float = column["head_y"] - trail_index * _cell_size
			if y < -_cell_size or y > size.y + _cell_size:
				continue

			var fade := 1.0 - float(trail_index) / float(trail_length)
			var color := Color(0.08, 1.0, 0.28, maxf(0.08, fade * 0.92))
			if trail_index == 0:
				color = Color(0.72, 1.0, 0.78, 1.0)
			draw_string(
				_font,
				Vector2(x, y),
				glyphs[trail_index],
				HORIZONTAL_ALIGNMENT_LEFT,
				-1.0,
				font_size,
				color
			)


func _rebuild_columns() -> void:
	if size.x < 1.0 or size.y < 1.0:
		return

	_columns.clear()
	_cell_size = clampf(size.y / 22.0, 14.0, 22.0)
	var column_count := maxi(1, int(floor(size.x / _cell_size)))
	for _column_index in column_count:
		var column: Dictionary = {
			"head_y": _rng.randf_range(-size.y, size.y * 0.85),
			"speed": _rng.randf_range(55.0, 118.0) * speed_scale,
			"trail_length": _rng.randi_range(8, 18),
			"change_timer": _rng.randf_range(0.02, 0.15),
			"glyphs": PackedStringArray(),
		}
		_fill_glyphs(column)
		_columns.append(column)
	queue_redraw()


func _reset_column(column: Dictionary, above_screen: bool) -> void:
	column["head_y"] = (
		_rng.randf_range(-size.y * 0.8, -_cell_size)
		if above_screen
		else _rng.randf_range(-size.y, size.y)
	)
	column["speed"] = _rng.randf_range(55.0, 118.0) * speed_scale
	column["trail_length"] = _rng.randi_range(8, 18)
	column["change_timer"] = _rng.randf_range(0.02, 0.15)
	_fill_glyphs(column)


func _fill_glyphs(column: Dictionary) -> void:
	var glyphs := PackedStringArray()
	for _glyph_index in column["trail_length"]:
		glyphs.append(_random_character())
	column["glyphs"] = glyphs


func _random_character() -> String:
	return CHARACTERS[_rng.randi_range(0, CHARACTERS.length() - 1)]
