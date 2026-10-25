extends SceneTree


func _fail(reason: String) -> void:
	print("FAIL: " + reason)
	quit(1)


func _initialize() -> void:
	await process_frame

	_ensure_autoloads()

	var room_scene := load("res://scenes/stage1/stage_1_room.tscn") as PackedScene
	if room_scene == null:
		return _fail("Failed to load stage_1_room.tscn")

	var room := room_scene.instantiate() as Node3D
	if room == null:
		return _fail("Failed to instantiate stage_1_room.tscn")

	root.add_child(room)

	# Wait 3 frames
	await process_frame
	await process_frame
	await process_frame

	var door_col := room.get_node_or_null("BulkheadDoors/NorthBulkheadDoor/DoorCollision") as CollisionShape3D
	if door_col == null:
		return _fail("Could not find BulkheadDoors/NorthBulkheadDoor/DoorCollision")

	door_col.disabled = true

	# Wait 2 physics frames
	await physics_frame
	await physics_frame

	var space_state := room.get_world_3d().direct_space_state

	# Raycast 1: through north doorway opening into corridor stub
	var query1 := PhysicsRayQueryParameters3D.create(
		Vector3(0.0, 1.3, -4.0),
		Vector3(0.0, 1.3, -9.5)
	)
	var hit1 := space_state.intersect_ray(query1)
	if hit1.is_empty():
		return _fail("Raycast 1 through opening hit nothing")

	var hit1_pos: Vector3 = hit1.get("position", Vector3.ZERO)
	if not (hit1_pos.z < -7.5):
		return _fail("Expected hit1_pos.z < -7.5, got %f" % hit1_pos.z)

	# Raycast 2: beside opening (wall still solid)
	var query2 := PhysicsRayQueryParameters3D.create(
		Vector3(-3.5, 1.3, -4.0),
		Vector3(-3.5, 1.3, -6.0)
	)
	var hit2 := space_state.intersect_ray(query2)
	if hit2.is_empty():
		return _fail("Raycast 2 beside opening hit nothing")

	var hit2_pos: Vector3 = hit2.get("position", Vector3.ZERO)
	if abs(hit2_pos.z - (-5.0)) > 0.3:
		return _fail("Expected hit2_pos.z ≈ -5.0, got %f" % hit2_pos.z)

	print("PASS")
	quit(0)


func _ensure_autoloads() -> void:
	var autoloads: Array[Array] = [
		["SaveData", "res://scripts/systems/save_data.gd"],
		["MalfunctionManager", "res://scripts/systems/malfunction_manager.gd"],
		["MinigameHost", "res://scenes/ui/minigame_host.tscn"],
		["MissionLog", "res://scripts/systems/mission_log.gd"],
		["Voice", "res://scripts/systems/voice.gd"],
		["LifeSupport", "res://scripts/systems/life_support.gd"],
		["SpaceWeather", "res://scripts/systems/space_weather.gd"],
		["PeopleInSpace", "res://scripts/systems/people_in_space.gd"],
	]
	for item: Array in autoloads:
		var node_name: String = item[0]
		var path: String = item[1]
		if root.get_node_or_null(node_name) == null and ResourceLoader.exists(path):
			var res = load(path)
			if res is PackedScene:
				var node: Node = res.instantiate()
				node.name = node_name
				root.add_child(node)
			elif res is GDScript:
				var node: Node = res.new()
				node.name = node_name
				root.add_child(node)
