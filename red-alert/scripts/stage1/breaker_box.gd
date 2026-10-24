extends Node3D

@export_range(45.0, 180.0, 1.0) var open_angle_degrees: float = 180.0
@export_range(0.1, 1.5, 0.05) var animation_duration: float = 0.45

@onready var cover_hinge: Node3D = $CoverHinge
@onready var fix_station: FixStation = get_node_or_null("PowerStation")

var is_open: bool = false
var prompt_text: String:
	get:
		var station := fix_station if fix_station != null else get_node_or_null("PowerStation") as FixStation
		if is_open and station != null and station.enabled:
			return "Fix: Power failure"
		return "Close breaker box" if is_open else "Open breaker box"
var _cover_tween: Tween


func interact(_interactor: Node = null) -> void:
	var station := fix_station if fix_station != null else get_node_or_null("PowerStation") as FixStation
	if is_open and station != null and station.enabled:
		station.interact(_interactor)
		return

	is_open = not is_open
	if _cover_tween and _cover_tween.is_valid():
		_cover_tween.kill()

	var target_angle := deg_to_rad(open_angle_degrees) if is_open else 0.0
	_cover_tween = create_tween()
	_cover_tween.set_trans(Tween.TRANS_QUINT)
	_cover_tween.set_ease(Tween.EASE_OUT)
	_cover_tween.tween_property(
		cover_hinge, "rotation:y", target_angle, animation_duration
	)
