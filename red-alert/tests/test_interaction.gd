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
	var key_shape := key.get_node("CollisionShape3D")
	if interactor._find_interactable(key_shape) != key:
		return _fail("lookup did not resolve the console key")
	key.enabled = false
	if interactor._find_interactable(key_shape) != null:
		return _fail("disabled interactable was still targetable")

	print("PASS")
	quit(0)
