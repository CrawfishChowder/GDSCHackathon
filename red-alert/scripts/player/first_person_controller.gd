extends CharacterBody3D

@export_category("Movement")
@export_range(1.0, 12.0, 0.1) var move_speed: float = 5.0
@export_range(1.0, 20.0, 0.1) var acceleration: float = 12.0
@export_range(1.0, 20.0, 0.1) var deceleration: float = 16.0
@export_range(1.0, 10.0, 0.1) var jump_velocity: float = 4.5

@export_category("Look")
@export_range(0.0005, 0.01, 0.0001) var mouse_sensitivity: float = 0.0063
@export_range(0.0005, 0.01, 0.0001) var fallback_mouse_sensitivity: float = 0.0077
@export_range(45.0, 89.0, 1.0) var max_pitch_degrees: float = 80.0
# Higher = snappier mouse look.
@export_range(1.0, 60.0, 0.5) var look_smoothing: float = 30.0
@export_range(16.0, 512.0, 1.0) var max_mouse_delta: float = 256.0
@export_range(0.1, 2.0, 0.05) var capture_probe_seconds: float = 0.6
@export_range(0.05, 0.5, 0.01) var stick_deadzone: float = 0.18
@export_range(0.5, 8.0, 0.1) var stick_look_speed: float = 3.0

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
var _target_yaw: float = 0.0
var _target_pitch: float = 0.0
var _mouse_guard_frames: int = 0
var _capture_probe_remaining: float = 0.0
var _received_captured_motion: bool = false
var _mouse_look_active: bool = false
var _mouse_look_mode: int = MouseLookMode.CAPTURED
var _last_fallback_position: Vector2 = Vector2.ZERO
var _has_fallback_position: bool = false
# Console chair the player is sitting in (Scott). Chairs call sit_in/stand_up.
var _active_seat: Node3D
# Head bob & camera shake (T9c1)
var _bob_time: float = 0.0
var _shake_strength: float = 0.0
var _shake_duration: float = 0.0
var _shake_timer: float = 0.0
var _reduce_motion: bool = false

enum MouseLookMode {
	CAPTURED,
	FALLBACK,
}

const MOUSE_TRANSITION_GUARD_FRAMES := 3


func _ready() -> void:
	# Always begin level instances looking horizontally along their local forward axis.
	rotation.x = 0.0
	rotation.z = 0.0
	head.rotation = Vector3.ZERO
	camera.rotation = Vector3.ZERO
	camera.position = Vector3.ZERO
	_target_yaw = rotation.y
	_target_pitch = 0.0
	_update_reduce_motion()
	_set_mouse_look_active(true)
	_connect_malfunction_manager()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_action_pressed("ui_cancel"):
		_set_mouse_look_active(not _mouse_look_active)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("interact") and is_instance_valid(_active_seat):
		stand_up()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseMotion and _mouse_look_active:
		if _mouse_look_mode == MouseLookMode.CAPTURED:
			_apply_captured_mouse_motion(event)
		else:
			_apply_fallback_mouse_motion(event)


func _process(delta: float) -> void:
	var stick := Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
	if stick.length() > stick_deadzone:
		var strength := (stick.length() - stick_deadzone) / (1.0 - stick_deadzone)
		_apply_look_delta(stick.normalized() * strength * delta, stick_look_speed)
	# PS Vita right stick arrives as look_* actions from VitaBridge (Brandon).
	var remote_look := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	if not remote_look.is_zero_approx():
		_apply_look_delta(remote_look * delta, stick_look_speed)
	if _mouse_guard_frames > 0:
		_mouse_guard_frames -= 1

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

	_update_reduce_motion()
	_update_head_bob(delta)
	_update_shake(delta)


func sit_in(seat: Node3D) -> bool:
	if is_instance_valid(_active_seat) or not seat.has_method("get_sit_transform"):
		return false
	_active_seat = seat
	velocity = Vector3.ZERO
	_bob_time = 0.0
	camera.position = Vector3.ZERO
	collision_shape.disabled = true
	_apply_seat_transform(seat.get_sit_transform())
	return true


func stand_up() -> void:
	var seat := _active_seat
	_active_seat = null
	if is_instance_valid(seat) and seat.has_method("get_stand_transform"):
		_apply_seat_transform(seat.get_stand_transform())
	collision_shape.disabled = false
	velocity = Vector3.ZERO
	_bob_time = 0.0
	camera.position = Vector3.ZERO
	if is_instance_valid(seat) and seat.has_method("release"):
		seat.release(self)


func is_seated() -> bool:
	return is_instance_valid(_active_seat)


func _apply_seat_transform(target_transform: Transform3D) -> void:
	global_position = target_transform.origin
	rotation = Vector3(0.0, target_transform.basis.get_euler().y, 0.0)
	head.rotation = Vector3.ZERO
	_target_yaw = rotation.y
	_target_pitch = 0.0
	_reset_mouse_tracking_after_transform()


func _apply_captured_mouse_motion(event: InputEventMouseMotion) -> void:
	# Godot recommends screen_relative for captured first-person aiming. Unlike
	# relative, it is not changed by viewport scaling. Some remote desktop
	# clients report the capture/recenter warp as a very large motion event, so
	# briefly ignore capture events and reject impossible single-frame deltas.
	if _mouse_guard_frames > 0:
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
	if _mouse_guard_frames > 0:
		_last_fallback_position = event.position
		_has_fallback_position = true
		return
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
	var sens_mult: float = 1.0
	var invert: bool = false
	var settings := get_node_or_null("/root/Settings")
	if settings != null and settings.has_method("get_setting"):
		var s_val: Variant = settings.get_setting("mouse_sensitivity")
		if s_val != null:
			sens_mult = float(s_val)
		var inv_val: Variant = settings.get_setting("invert_y")
		if inv_val != null:
			invert = bool(inv_val)
	var eff_sens := sensitivity * sens_mult
	var pitch_delta := mouse_delta.y * eff_sens
	if invert:
		pitch_delta = -pitch_delta
	_target_yaw = wrapf(
		_target_yaw - mouse_delta.x * eff_sens, -PI, PI
	)
	_target_pitch = clamp(
		_target_pitch - pitch_delta,
		-deg_to_rad(max_pitch_degrees),
		deg_to_rad(max_pitch_degrees)
	)


# Called by overlays (minigames, pause menu) when they hand control back, so mouse
# look restarts through the normal capture path instead of a raw mouse_mode set.
func resume_mouse_look() -> void:
	_set_mouse_look_active(true)


func _set_mouse_look_active(active: bool) -> void:
	_mouse_look_active = active
	_target_yaw = rotation.y
	_target_pitch = head.rotation.x
	if active:
		_start_captured_mouse_look()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_mouse_guard_frames = 0
		_has_fallback_position = false


func _start_captured_mouse_look() -> void:
	_mouse_look_mode = MouseLookMode.CAPTURED
	_received_captured_motion = false
	_capture_probe_remaining = capture_probe_seconds
	_mouse_guard_frames = MOUSE_TRANSITION_GUARD_FRAMES
	_has_fallback_position = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _enable_fallback_mouse_look() -> void:
	if not _mouse_look_active:
		return
	_mouse_look_mode = MouseLookMode.FALLBACK
	_mouse_guard_frames = 0
	_has_fallback_position = false
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN


func _reset_mouse_tracking_after_transform() -> void:
	_mouse_guard_frames = MOUSE_TRANSITION_GUARD_FRAMES
	_last_fallback_position = Vector2.ZERO
	_has_fallback_position = false
	if _mouse_look_active and _mouse_look_mode == MouseLookMode.CAPTURED:
		_received_captured_motion = false
		_capture_probe_remaining = capture_probe_seconds
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


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

	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back", 0.18)
	var move_direction := (
		transform.basis * Vector3(input_vector.x, 0.0, input_vector.y)
	).normalized()
	var target_velocity := move_direction * move_speed
	var rate := acceleration if move_direction != Vector3.ZERO else deceleration

	velocity.x = move_toward(velocity.x, target_velocity.x, rate * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, rate * delta)
	move_and_slide()


func _update_reduce_motion() -> void:
	var settings := get_node_or_null("/root/Settings")
	if settings != null and settings.has_method("get_setting"):
		_reduce_motion = bool(settings.get_setting("reduce_motion"))
	else:
		_reduce_motion = false


func shake(strength: float, duration: float) -> void:
	_update_reduce_motion()
	if _reduce_motion:
		return
	if strength <= 0.0 or duration <= 0.0:
		return
	_shake_strength = strength
	_shake_duration = duration
	_shake_timer = duration
	if camera == null:
		return
	var max_rad := deg_to_rad(strength * 1.5)
	camera.rotation = Vector3(
		randf_range(-max_rad, max_rad),
		randf_range(-max_rad, max_rad),
		randf_range(-max_rad, max_rad)
	)
	if camera.rotation.is_zero_approx():
		camera.rotation.x = max_rad


func _update_shake(delta: float) -> void:
	if camera == null:
		return
	if _reduce_motion:
		if camera.rotation != Vector3.ZERO:
			camera.rotation = Vector3.ZERO
		_shake_timer = 0.0
		return
	if _shake_timer <= 0.0:
		if camera.rotation != Vector3.ZERO:
			camera.rotation = Vector3.ZERO
		return
	_shake_timer = maxf(_shake_timer - delta, 0.0)
	if _shake_timer <= 0.0:
		camera.rotation = Vector3.ZERO
		return
	var decay := _shake_timer / _shake_duration
	var max_rad := deg_to_rad(_shake_strength * 1.5) * decay
	camera.rotation = Vector3(
		randf_range(-max_rad, max_rad),
		randf_range(-max_rad, max_rad),
		randf_range(-max_rad, max_rad)
	)
	if camera.rotation.is_zero_approx():
		camera.rotation.x = max_rad * 0.5


func _update_head_bob(delta: float) -> void:
	if camera == null:
		return
	if _reduce_motion:
		_bob_time = 0.0
		camera.position = Vector3.ZERO
		return
	if is_seated():
		_bob_time = 0.0
		camera.position.x = move_toward(camera.position.x, 0.0, delta * 0.15)
		camera.position.y = move_toward(camera.position.y, 0.0, delta * 0.15)
		return

	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	if is_on_floor() and horizontal_speed > 0.1:
		_bob_time += delta
		var speed_factor := horizontal_speed / maxf(move_speed, 0.001)
		camera.position.x = cos(_bob_time * 4.5) * 0.02
		camera.position.y = sin(_bob_time * 9.0) * 0.035 * speed_factor
	else:
		_bob_time = 0.0
		camera.position.x = move_toward(camera.position.x, 0.0, delta * 0.15)
		camera.position.y = move_toward(camera.position.y, 0.0, delta * 0.15)


func _connect_malfunction_manager() -> void:
	var mm := get_node_or_null("/root/MalfunctionManager")
	if mm == null:
		return
	if mm.has_signal("malfunction_started"):
		mm.connect("malfunction_started", _on_malfunction_started)
	if mm.has_signal("practice_mistake"):
		mm.connect("practice_mistake", _on_practice_mistake)
	if mm.has_signal("player_died"):
		mm.connect("player_died", _on_player_died)


func _on_malfunction_started(_id: Variant = "", _display_name: Variant = "", _time_limit: Variant = 0.0) -> void:
	shake(0.6, 0.5)


func _on_practice_mistake(_cause_id: Variant = "", _detail: Variant = "") -> void:
	shake(1.2, 0.6)


func _on_player_died(_cause_id: Variant = "", _display_name: Variant = "") -> void:
	shake(2.0, 0.8)
