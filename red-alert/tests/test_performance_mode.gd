extends SceneTree

var got := {}


func _fail(reason: String) -> void:
	if root != null:
		paused = false
	print("FAIL: " + reason)
	quit(1)


func _initialize() -> void:
	await process_frame

	var sd: Node = root.get_node_or_null("SaveData")
	if sd == null:
		var sd_script := load("res://scripts/systems/save_data.gd") as GDScript
		if sd_script == null:
			return _fail("Failed to load save_data.gd")
		sd = sd_script.new()
		sd.name = "SaveData"
		root.add_child(sd)
		await process_frame

	var settings: Node = root.get_node_or_null("Settings")
	if settings == null:
		var settings_script := load("res://scripts/systems/settings.gd") as GDScript
		if settings_script == null:
			return _fail("Failed to load settings.gd")
		settings = settings_script.new()
		settings.name = "Settings"
		root.add_child(settings)
		await process_frame

	# Ensure clean baseline
	settings.call("set_setting", "performance_mode", false)
	settings.call("set_setting", "shadows", true)
	await process_frame

	var default_perf: Variant = settings.call("get_setting", "performance_mode")
	if bool(default_perf) != false:
		return _fail("Expected performance_mode default to be false, got %s" % default_perf)

	# 1. Set performance_mode true
	settings.call("set_setting", "performance_mode", true)
	await process_frame

	var shadows_val: Variant = settings.call("get_setting", "shadows")
	if bool(shadows_val) != false:
		return _fail("Expected shadows to be forced off in performance mode, got %s" % shadows_val)

	if not is_equal_approx(root.scaling_3d_scale, 0.75):
		return _fail("Expected root scaling_3d_scale == 0.75 in performance mode, got %f" % root.scaling_3d_scale)

	# 2. Instance room and wait 2 frames
	var room_scene := load("res://scenes/stage1/stage_1_room.tscn") as PackedScene
	if room_scene == null:
		return _fail("Failed to load stage_1_room.tscn")
	var room: Node = room_scene.instantiate()
	root.add_child(room)
	await process_frame
	await process_frame

	# 3. Assert WorldEnvironment has fog_enabled == false and glow_enabled == false
	var we := room.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if we == null or we.environment == null:
		room.queue_free()
		return _fail("WorldEnvironment or environment not found in room")
	if we.environment.fog_enabled != false:
		room.queue_free()
		return _fail("Expected fog_enabled == false in performance mode, got %s" % we.environment.fog_enabled)
	if we.environment.glow_enabled != false:
		room.queue_free()
		return _fail("Expected glow_enabled == false in performance mode, got %s" % we.environment.glow_enabled)

	# 4. Check monitor viewports cap resolution at 512x288
	var normal_ops: Node = room.get_node_or_null("NormalOperations")
	if normal_ops != null and normal_ops.has_method("get_monitor_ids"):
		var monitor_ids: Array = normal_ops.call("get_monitor_ids")
		for mid in monitor_ids:
			var res: Vector2i = normal_ops.call("get_monitor_resolution", mid)
			if res.x > 512 or res.y > 288:
				room.queue_free()
				return _fail("Monitor %s resolution %s exceeded 512x288" % [mid, res])

	# 5. Toggle performance_mode to false and verify live updates
	settings.call("set_setting", "performance_mode", false)
	await process_frame
	if we.environment.fog_enabled != true:
		room.queue_free()
		return _fail("Expected fog_enabled == true when performance mode toggled off")
	if we.environment.glow_enabled != true:
		room.queue_free()
		return _fail("Expected glow_enabled == true when performance mode toggled off")
	if not is_equal_approx(root.scaling_3d_scale, 1.0):
		room.queue_free()
		return _fail("Expected scaling_3d_scale == 1.0 when performance mode toggled off, got %f" % root.scaling_3d_scale)

	# 6. Reset setting and clean up
	room.queue_free()
	await process_frame
	settings.call("set_setting", "performance_mode", false)
	await process_frame

	paused = false
	print("PASS")
	quit(0)
