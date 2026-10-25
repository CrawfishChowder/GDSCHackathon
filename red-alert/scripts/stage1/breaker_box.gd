extends Node3D

signal main_breaker_changed(is_on: bool)

@export_range(45.0, 180.0, 1.0) var open_angle_degrees: float = 180.0
@export_range(0.1, 1.5, 0.05) var animation_duration: float = 0.45

@onready var cover_hinge: Node3D = $CoverHinge
@onready var main_breaker_handle: MeshInstance3D = $EnclosureBody/MainBreakerHandle
@onready var handle_hitbox: CollisionShape3D = $MainBreakerInteraction/CollisionShape3D

var is_open: bool = false
var is_main_breaker_on: bool = true
var prompt_text: String:
	get:
		if is_open:
			return "Close breaker cover"
		var mm: Node = get_node_or_null("/root/MalfunctionManager")
		if mm != null and mm.get("active_id") == "power":
			return "Open breaker cover (POWER FAILURE)"
		return "Open breaker cover"

var _cover_tween: Tween
var _handle_tween: Tween


func _ready() -> void:
	handle_hitbox.disabled = true


func interact(_interactor: Node = null) -> void:
	is_open = not is_open
	handle_hitbox.set_deferred("disabled", not is_open)
	if _cover_tween and _cover_tween.is_valid():
		_cover_tween.kill()

	var target_angle := deg_to_rad(open_angle_degrees) if is_open else 0.0
	_cover_tween = create_tween()
	_cover_tween.set_trans(Tween.TRANS_QUINT)
	_cover_tween.set_ease(Tween.EASE_OUT)
	_cover_tween.tween_property(
		cover_hinge, "rotation:y", target_angle, animation_duration
	)


func get_main_breaker_prompt() -> String:
	if not is_open:
		return ""
	var mm: Node = get_node_or_null("/root/MalfunctionManager")
	var is_power_active: bool = (mm != null and mm.get("active_id") == "power")
	if is_power_active:
		return "Main breaker OFF (step 1 of 2)" if is_main_breaker_on else "Main breaker ON (step 2 of 2)"
	return "Turn main breaker OFF" if is_main_breaker_on else "Turn main breaker ON"


func toggle_main_breaker() -> void:
	if not is_open:
		return

	is_main_breaker_on = not is_main_breaker_on
	if _handle_tween and _handle_tween.is_valid():
		_handle_tween.kill()

	var target_angle := deg_to_rad(-12.0 if is_main_breaker_on else 168.0)
	_handle_tween = create_tween()
	_handle_tween.set_trans(Tween.TRANS_QUINT)
	_handle_tween.set_ease(Tween.EASE_OUT)
	_handle_tween.tween_property(
		main_breaker_handle, "rotation:x", target_angle, animation_duration
	)
	main_breaker_changed.emit(is_main_breaker_on)
