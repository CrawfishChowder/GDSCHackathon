extends SceneTree


func _initialize() -> void:
	await process_frame

	var mm: Node = root.get_node_or_null("MalfunctionManager")
	if mm == null:
		print("FAIL: MalfunctionManager autoload not found")
		quit(1)
		return

	var room_scene := load("res://scenes/stage1/stage_1_room.tscn") as PackedScene
	if room_scene == null:
		print("FAIL: Failed to load stage_1_room.tscn")
		quit(1)
		return

	var room: Node = room_scene.instantiate()
	if room == null:
		print("FAIL: Failed to instantiate stage_1_room.tscn")
		quit(1)
		return

	root.add_child(room)
	await process_frame

	var alarm_controller: Node = room.get_node_or_null("AlarmController")
	if alarm_controller == null:
		print("FAIL: AlarmController not found under room")
		quit(1)
		return

	mm.start_run()
	mm.trigger("o2")
	await process_frame

	var ping_player: AudioStreamPlayer3D = null
	for child in alarm_controller.get_children():
		if child is AudioStreamPlayer3D:
			ping_player = child
			break

	if ping_player == null:
		print("FAIL: AlarmController does not have a child AudioStreamPlayer3D after trigger(o2)")
		quit(1)
		return

	var expected_pos := Vector3(-2.13, 1.4, 3.9)
	if not ping_player.position.is_equal_approx(expected_pos):
		print("FAIL: AudioStreamPlayer3D position %s does not match expected %s" % [str(ping_player.position), str(expected_pos)])
		quit(1)
		return

	mm.fix("o2")
	await process_frame

	var is_stopped_or_freed: bool = (
		not is_instance_valid(ping_player)
		or ping_player.is_queued_for_deletion()
		or not ping_player.playing
		or ping_player.get_parent() == null
	)

	if not is_stopped_or_freed:
		print("FAIL: AudioStreamPlayer3D is neither stopped nor freed after fix(o2)")
		quit(1)
		return

	room.queue_free()
	await process_frame

	print("PASS")
	quit(0)
