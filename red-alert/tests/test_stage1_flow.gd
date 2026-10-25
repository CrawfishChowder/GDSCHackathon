extends SceneTree


func _initialize() -> void:
	await process_frame

	var room_scene := load("res://scenes/stage1/stage_1_room.tscn") as PackedScene
	if room_scene == null:
		print("FAIL: Failed to load stage_1_room scene")
		quit(1)
		return

	var room := room_scene.instantiate()
	if room == null:
		print("FAIL: Failed to instantiate stage_1_room scene")
		quit(1)
		return

	root.add_child(room)
	await process_frame

	var north_door := room.get_node_or_null("BulkheadDoors/NorthBulkheadDoor")
	var east_door := room.get_node_or_null("BulkheadDoors/EastBulkheadDoor")
	var west_door := room.get_node_or_null("BulkheadDoors/WestBulkheadDoor")

	if north_door == null or east_door == null or west_door == null:
		paused = false
		print("FAIL: Bulkhead doors not found")
		quit(1)
		return

	var mm: Node = root.get_node("MalfunctionManager")
	if mm == null:
		paused = false
		print("FAIL: MalfunctionManager not found")
		quit(1)
		return

	mm.start_run()
	mm.set("survived_seconds", float(mm.get("SHIFT_LENGTH")) - 0.05)

	await create_timer(0.3, true).timeout

	paused = false

	if north_door.is_sealed():
		print("FAIL: North bulkhead door is still sealed")
		quit(1)
		return

	if not east_door.is_sealed():
		print("FAIL: East bulkhead door should remain sealed")
		quit(1)
		return

	if not west_door.is_sealed():
		print("FAIL: West bulkhead door should remain sealed")
		quit(1)
		return

	print("PASS")
	quit(0)
