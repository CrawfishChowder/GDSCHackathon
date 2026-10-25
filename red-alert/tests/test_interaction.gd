extends SceneTree


func _fail(reason: String) -> void:
	print("FAIL: " + reason)
	quit(1)


func _press_interact() -> void:
	var event := InputEventAction.new()
	event.action = "interact"
	event.pressed = true
	root.push_input(event)


func _initialize() -> void:
	var room := (load("res://scenes/stage1/stage_1_room.tscn") as PackedScene).instantiate()
	root.add_child(room)
	await process_frame

	var player := room.get_node("FirstPersonPlayer") as Node3D
	var interactor := player.get_node("Head/Camera3D/Interactor")
	var prompt_label := player.get_node("HUD/PromptLabel") as Label
	var breaker := room.get_node("WallFixtures/NorthDoorBreakerBox")
	var key := room.get_node("MainConsole/CenterStation/EmergencyReleaseKey") as Interactable

	# Stand in front of the north-wall breaker box, facing it (-Z), eye level ~1.55.
	player.global_position = Vector3(2.8, 0.9, -3.2)
	for i in 10:
		await physics_frame

	if not prompt_label.visible or prompt_label.text != "[E] Open breaker cover":
		return _fail("breaker prompt not shown, got '%s'" % prompt_label.text)

	_press_interact()
	await process_frame
	if not breaker.is_open:
		return _fail("pressing interact did not open the breaker box")

	await physics_frame
	if prompt_label.text != "[E] Close breaker cover":
		return _fail("prompt did not update after opening, got '%s'" % prompt_label.text)

	# Parent-walk lookup: the key's collision shape resolves to the Interactable.
	# The emergency key is disabled in play (relief-crew ending); enable it here
	# just to exercise the parent-walk lookup.
	key.enabled = true
	var key_shape := key.get_node("CollisionShape3D")
	if interactor._find_interactable(key_shape) != key:
		return _fail("lookup did not resolve the console key")
	key.enabled = false
	if interactor._find_interactable(key_shape) != null:
		return _fail("disabled interactable was still targetable")

	# Scott's chairs still use the shared interact action after the player merge.
	var chair := room.get_node("ConsoleChairs/CenterConsoleChair")
	player._mouse_look_mode = player.MouseLookMode.FALLBACK
	player._has_fallback_position = true
	player._last_fallback_position = Vector2(900.0, 700.0)
	chair.interact(player)
	if not player.is_seated():
		return _fail("chair interaction did not seat the player")
	if player._has_fallback_position or player._mouse_guard_frames != 3:
		return _fail("sitting did not reset and guard fallback mouse tracking")
	var stand_event := InputEventAction.new()
	stand_event.action = "interact"
	stand_event.pressed = true
	player._unhandled_input(stand_event)
	if player.is_seated():
		return _fail("interact did not stand the seated player")
	if chair.occupant != null:
		return _fail("chair did not release its occupant")
	if player._has_fallback_position or player._mouse_guard_frames != 3:
		return _fail("standing did not reset and guard fallback mouse tracking")
	var warp_event := InputEventMouseMotion.new()
	warp_event.position = Vector2(100.0, 100.0)
	var yaw_before_warp: float = player._target_yaw
	player._apply_fallback_mouse_motion(warp_event)
	if not is_equal_approx(player._target_yaw, yaw_before_warp):
		return _fail("post-chair fallback pointer warp changed camera yaw")
	player._mouse_look_mode = player.MouseLookMode.CAPTURED
	player._received_captured_motion = true
	chair.interact(player)
	if player._received_captured_motion or player._capture_probe_remaining <= 0.0:
		return _fail("sitting did not rearm captured-mode health detection")
	player.stand_up()

	print("PASS")
	quit(0)
