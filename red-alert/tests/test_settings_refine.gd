extends SceneTree


func _initialize() -> void:
	await process_frame

	var settings: Node = root.get_node_or_null("Settings")
	if settings == null:
		print("FAIL: Settings autoload not found")
		quit(1)
		return

	# Set reduce_motion to true
	settings.call("set_setting", "reduce_motion", true)

	# Instance the player scene
	var player_scene := load("res://scenes/player/first_person_player.tscn") as PackedScene
	if player_scene == null:
		print("FAIL: Failed to load first_person_player.tscn")
		quit(1)
		return

	var player := player_scene.instantiate() as Node
	if player == null:
		print("FAIL: Failed to instantiate first_person_player")
		quit(1)
		return

	root.add_child(player)

	# Call shake(1.0, 0.5)
	player.call("shake", 1.0, 0.5)

	# Wait 1 frame
	await process_frame

	# Assert camera rotation is zero
	var cam: Camera3D = player.get_node_or_null("Head/Camera3D") as Camera3D
	if cam == null:
		print("FAIL: Head/Camera3D not found on player")
		quit(1)
		return

	if not cam.rotation.is_zero_approx():
		print("FAIL: camera rotation is not zero with reduce_motion enabled: %s" % str(cam.rotation))
		quit(1)
		return

	# Reset setting to false
	settings.call("set_setting", "reduce_motion", false)
	player.queue_free()

	# Set sfx_volume to 0.5 and assert the "SFX" bus volume is about -6 dB (±0.5), if that bus exists
	settings.call("set_setting", "sfx_volume", 0.5)
	var sfx_idx := AudioServer.get_bus_index("SFX")
	if sfx_idx != -1:
		var db := AudioServer.get_bus_volume_db(sfx_idx)
		if abs(db - (-6.0)) > 0.5:
			print("FAIL: SFX bus volume %f dB is not about -6.0 dB" % db)
			quit(1)
			return

	# Reset sfx_volume to 1.0
	settings.call("set_setting", "sfx_volume", 1.0)

	paused = false
	print("PASS")
	quit(0)
