extends CharacterBody3D

@export_category("Movement")
@export_range(1.0, 12.0, 0.1) var move_speed: float = 5.0
@export_range(1.0, 20.0, 0.1) var acceleration: float = 12.0
@export_range(1.0, 20.0, 0.1) var deceleration: float = 16.0
@export_range(1.0, 10.0, 0.1) var jump_velocity: float = 4.5

@export_category("Look")
@export_range(0.0005, 0.01, 0.0001) var mouse_sensitivity: float = 0.0036
@export_range(0.0005, 0.01, 0.0001) var fallback_mouse_sensitivity: float = 0.0044
@export_range(45.0, 89.0, 1.0) var max_pitch_degrees: float = 80.0
@export_range(1.0, 30.0, 0.5) var look_smoothing: float = 18.0
@export_range(16.0, 512.0, 1.0) var max_mouse_delta: float = 256.0
@export_range(0.1, 2.0, 0.05) var capture_probe_seconds: float = 0.6

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var interaction_ray: RayCast3D = $Head/Camera3D/InteractionRay
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
var _target_yaw: float = 0.0
var _target_pitch: float = 0.0
var _capture_guard_frames: int = 0
var _capture_probe_remaining: float = 0.0
var _received_captured_motion: bool = false
var _mouse_look_active: bool = false
var _mouse_look_mode: int = MouseLookMode.CAPTURED
var _last_fallback_position: Vector2 = Vector2.ZERO
var _has_fallback_position: bool = false
var _active_seat: Node3D

enum MouseLookMode {
	CAPTURED,
	FALLBACK,
}


func _ready() -> void:
	# Always begin level instances looking horizontally along their local forward axis.
	rotation.x = 0.0
	rotation.z = 0.0
	head.rotation = Vector3.ZERO
	camera.rotation = Vector3.ZERO
	_target_yaw = rotation.y
	_target_pitch = 0.0
	_set_mouse_look_active(true)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_set_mouse_look_active(not _mouse_look_active)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("interact"):
		if is_instance_valid(_active_seat):
			stand_up()
		else:
			_try_interact()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseMotion and _mouse_look_active:
		if _mouse_look_mode == MouseLookMode.CAPTURED:
			_apply_captured_mouse_motion(event)
		else:
			_apply_fallback_mouse_motion(event)


func _process(delta: float) -> void:
	if _capture_guard_frames > 0:
		_capture_guard_frames -= 1

	if (
		_mouse_look_active
		and _mouse_look_mode == MouseLookMode.CAPTURED
		and not _received_captured_motion
	):
		_capture_probe_remaining -= delta
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED or _capture_probe_remaining <= 0.0:
			_enable_fallback_mouse_look()

	var smoothing_weight := 1.0 - exp(-look_smoothing * delta)
	rotation.y = lerp_angle(rotation.y, _target_yaw, smoothing_weight)
	head.rotation.x = lerp_angle(head.rotation.x, _target_pitch, smoothing_weight)


func _try_interact() -> void:
	var interaction_target := interaction_ray.get_collider() as Node
	while interaction_target:
		if interaction_target.has_method("interact"):
			interaction_target.interact(self)
			return
		interaction_target = interaction_target.get_parent()


func sit_in(seat: Node3D) -> bool:
	if is_instance_valid(_active_seat) or not seat.has_method("get_sit_transform"):
		return false

	_active_seat = seat
	velocity = Vector3.ZERO
	collision_shape.disabled = true
	_apply_seat_transform(seat.get_sit_transform())
	return true


func stand_up() -> void:
	if not is_instance_valid(_active_seat):
		_active_seat = null
		collision_shape.disabled = false
		return

	var seat := _active_seat
	_active_seat = null
	if seat.has_method("get_stand_transform"):
		_apply_seat_transform(seat.get_stand_transform())
	collision_shape.disabled = false
	velocity = Vector3.ZERO
	if seat.has_method("release"):
		seat.release(self)


func _apply_seat_transform(target_transform: Transform3D) -> void:
	global_position = target_transform.origin
	rotation.x = 0.0
	rotation.y = target_transform.basis.get_euler().y
	rotation.z = 0.0
	head.rotation = Vector3.ZERO
	_target_yaw = rotation.y
	_target_pitch = 0.0


func _apply_captured_mouse_motion(event: InputEventMouseMotion) -> void:
	# Godot recommends screen_relative for captured first-person aiming. Unlike
	# relative, it is not changed by viewport scaling. Some remote desktop
	# clients report the capture/recenter warp as a very large motion event, so
	# briefly ignore capture events and reject impossible single-frame deltas.
	if _capture_guard_frames > 0:
		return

	var mouse_delta := event.screen_relative
	if mouse_delta.is_zero_approx() and not event.relative.is_zero_approx():
		mouse_delta = event.relative
	if not _is_usable_mouse_delta(mouse_delta):
		return

	_received_captured_motion = true
	_apply_look_delta(mouse_delta, mouse_sensitivity)


func _apply_fallback_mouse_motion(event: InputEventMouseMotion) -> void:
	# Confined mode does not lock or recenter the pointer. This lets virtual
	# desktops deliver normal absolute mouse positions even when pointer capture
	# is unavailable. Never warp the pointer here: remote clients can interpret a
	# warp as real movement and feed it back as an uncontrolled look delta.
	if not _has_fallback_position:
		_last_fallback_position = event.position
		_has_fallback_position = true
		return

	var mouse_delta := event.position - _last_fallback_position
	_last_fallback_position = event.position
	if mouse_delta.is_zero_approx() and not event.relative.is_zero_approx():
		mouse_delta = event.relative
	if not _is_usable_mouse_delta(mouse_delta):
		return

	_apply_look_delta(mouse_delta, fallback_mouse_sensitivity)


func _is_usable_mouse_delta(mouse_delta: Vector2) -> bool:
	if mouse_delta.is_zero_approx():
		return false
	return abs(mouse_delta.x) <= max_mouse_delta and abs(mouse_delta.y) <= max_mouse_delta


func _apply_look_delta(mouse_delta: Vector2, sensitivity: float) -> void:
	_target_yaw = wrapf(
		_target_yaw - mouse_delta.x * sensitivity, -PI, PI
	)
	_target_pitch = clamp(
		_target_pitch - mouse_delta.y * sensitivity,
		-deg_to_rad(max_pitch_degrees),
		deg_to_rad(max_pitch_degrees)
	)


func _set_mouse_look_active(active: bool) -> void:
	_mouse_look_active = active
	_target_yaw = rotation.y
	_target_pitch = head.rotation.x
	if active:
		_start_captured_mouse_look()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_capture_guard_frames = 0
		_has_fallback_position = false


func _start_captured_mouse_look() -> void:
	_mouse_look_mode = MouseLookMode.CAPTURED
	_received_captured_motion = false
	_capture_probe_remaining = capture_probe_seconds
	_capture_guard_frames = 2
	_has_fallback_position = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _enable_fallback_mouse_look() -> void:
	if not _mouse_look_active:
		return
	_mouse_look_mode = MouseLookMode.FALLBACK
	_capture_guard_frames = 0
	_has_fallback_position = false
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN


func _physics_process(delta: float) -> void:
	if _active_seat != null and not is_instance_valid(_active_seat):
		_active_seat = null
		collision_shape.disabled = false

	if is_instance_valid(_active_seat):
		velocity = Vector3.ZERO
		global_position = _active_seat.get_sit_transform().origin
		return

	if not is_on_floor():
		velocity.y -= _gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var input_vector := Input.get_vector(
		"move_left", "move_right", "move_forward", "move_back"
	)
	var move_direction := (
		transform.basis * Vector3(input_vector.x, 0.0, input_vector.y)
	).normalized()
	var target_velocity := move_direction * move_speed
	var rate := acceleration if move_direction != Vector3.ZERO else deceleration

	velocity.x = move_toward(velocity.x, target_velocity.x, rate * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, rate * delta)
	move_and_slide()
