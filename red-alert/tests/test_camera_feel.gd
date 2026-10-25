extends SceneTree


func _fail(reason: String) -> void:
	paused = false
	print("FAIL: " + reason)
	quit(1)


func _initialize() -> void:
	await process_frame

	var player_scene := load("res://scenes/player/first_person_player.tscn") as PackedScene
	if player_scene == null:
		return _fail("Failed to load first_person_player.tscn")

	var player: Node = player_scene.instantiate()
	if player == null:
		return _fail("Failed to instantiate first_person_player.tscn")

	root.add_child(player)
	await process_frame

	var camera: Camera3D = player.get_node_or_null("Head/Camera3D") as Camera3D
	if camera == null:
		return _fail("Head/Camera3D not found on player")

	# 1. Test shake(1.0, 0.3): wait 1 frame, assert camera rotation is non-zero
	player.call("shake", 1.0, 0.3)
	await process_frame

	if camera.rotation.is_zero_approx():
		return _fail("Expected camera rotation to be non-zero after shake")

	# Wait 0.5 s and assert it's back near zero (is_zero_approx per axis, within 0.001)
	await create_timer(0.5).timeout
	await process_frame

	if not is_zero_approx(camera.rotation.x) and abs(camera.rotation.x) >= 0.001:
		return _fail("Expected camera rotation.x near zero, got %f" % camera.rotation.x)
	if not is_zero_approx(camera.rotation.y) and abs(camera.rotation.y) >= 0.001:
		return _fail("Expected camera rotation.y near zero, got %f" % camera.rotation.y)
	if not is_zero_approx(camera.rotation.z) and abs(camera.rotation.z) >= 0.001:
		return _fail("Expected camera rotation.z near zero, got %f" % camera.rotation.z)

	# 2. Test auto-shake via MalfunctionManager signals
	var mm: Node = root.get_node_or_null("MalfunctionManager")
	if mm != null:
		# malfunction_started -> shake(0.6, 0.5)
		mm.emit_signal("malfunction_started", "reactor", "Reactor meltdown", 45.0)
		await process_frame
		if camera.rotation.is_zero_approx():
			return _fail("Expected camera rotation non-zero after malfunction_started")

		# practice_mistake -> shake(1.2, 0.6)
		mm.emit_signal("practice_mistake", "o2", "Wrong code")
		await process_frame
		if camera.rotation.is_zero_approx():
			return _fail("Expected camera rotation non-zero after practice_mistake")

		# player_died -> shake(2.0, 0.8)
		mm.emit_signal("player_died", "o2", "O2 depletion")
		await process_frame
		if camera.rotation.is_zero_approx():
			return _fail("Expected camera rotation non-zero after player_died")

		# The real GameOver in the HUD pauses the tree on death, freezing the player;
		# unpause so the shake can finish decaying.
		await create_timer(0.1).timeout
		paused = false
		# Wait for shake decay (0.9 s > 0.8 s)
		await create_timer(0.9).timeout
		await process_frame
		if not is_zero_approx(camera.rotation.x) and abs(camera.rotation.x) >= 0.001:
			return _fail("Expected camera rotation.x near zero after decay, got %f" % camera.rotation.x)
		if not is_zero_approx(camera.rotation.y) and abs(camera.rotation.y) >= 0.001:
			return _fail("Expected camera rotation.y near zero after decay, got %f" % camera.rotation.y)
		if not is_zero_approx(camera.rotation.z) and abs(camera.rotation.z) >= 0.001:
			return _fail("Expected camera rotation.z near zero after decay, got %f" % camera.rotation.z)

	# 3. Test head bob: stopped and seated behavior
	if player.has_method("is_seated") and bool(player.call("is_seated")):
		return _fail("Player should not be seated initially")

	# Stopped camera position should be at zero
	await create_timer(0.2).timeout
	await process_frame
	if not is_zero_approx(camera.position.x) and abs(camera.position.x) >= 0.001:
		return _fail("Expected camera position.x near zero when stopped, got %f" % camera.position.x)
	if not is_zero_approx(camera.position.y) and abs(camera.position.y) >= 0.001:
		return _fail("Expected camera position.y near zero when stopped, got %f" % camera.position.y)

	player.queue_free()
	print("PASS")
	quit(0)
