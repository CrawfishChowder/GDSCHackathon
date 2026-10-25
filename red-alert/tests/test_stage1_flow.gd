extends SceneTree


func _initialize() -> void:
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

	var key := room.get_node_or_null("MainConsole/CenterStation/EmergencyReleaseKey") as Interactable
	if key == null:
		print("FAIL: EmergencyReleaseKey not found")
		quit(1)
		return

	var north_door := room.get_node_or_null("BulkheadDoors/NorthBulkheadDoor") as BulkheadDoor
	var east_door := room.get_node_or_null("BulkheadDoors/EastBulkheadDoor") as BulkheadDoor
	var west_door := room.get_node_or_null("BulkheadDoors/WestBulkheadDoor") as BulkheadDoor

	if north_door == null or east_door == null or west_door == null:
		print("FAIL: Bulkhead doors not found")
		quit(1)
		return

	key.interact(null)

	await create_timer(1.6).timeout

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

