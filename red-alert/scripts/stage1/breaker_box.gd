extends Node3D

@export_range(45.0, 180.0, 1.0) var open_angle_degrees: float = 180.0
@export_range(0.1, 1.5, 0.05) var animation_duration: float = 0.45

@onready var cover_hinge: Node3D = $CoverHinge

var is_open: bool = false
var _cover_tween: Tween


func interact(_interactor: Node = null) -> void:
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
