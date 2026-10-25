extends SceneTree


func _fail(reason: String) -> void:
	print("FAIL: " + reason)
	quit(1)


func _initialize() -> void:
	await process_frame

	var room_scene := load("res://scenes/stage1/stage_1_room.tscn") as PackedScene
	if room_scene == null:
		return _fail("Failed to load stage_1_room.tscn")

	var room := room_scene.instantiate()
	root.add_child(room)

	await process_frame
	await process_frame

	var room_props: Node = room.get_node_or_null("Polish/RoomProps")
	if room_props == null:
		return _fail("Polish/RoomProps not found in room scene")

	var mesh_instances: Array[MeshInstance3D] = []
	_collect_mesh_instances(room_props, mesh_instances)

	if mesh_instances.size() < 20:
		return _fail("Expected at least 20 descendant MeshInstance3D nodes, got %d" % mesh_instances.size())

	for mi in mesh_instances:
		if mi.mesh == null:
			continue
		var aabb: AABB = mi.mesh.get_aabb()
		var global_center: Vector3 = mi.global_transform * aabb.get_center()
		if _is_inside_console_box(global_center):
			return _fail("Prop '%s' global AABB center %s lies inside console box" % [mi.name, str(global_center)])

	var locker_0 := room_props.get_node_or_null("Locker_0")
	if locker_0 != null:
		return _fail("Removed rightmost Locker_0 is still present")
	var locker_1 := room_props.get_node_or_null("Locker_1")
	if locker_1 == null:
		return _fail("Remaining Locker_1 node not found")
	var has_col := false
	for child in locker_1.get_children():
		if child is StaticBody3D:
			for col in child.get_children():
				if col is CollisionShape3D:
					has_col = true
	if not has_col:
		return _fail("Locker_1 missing StaticBody3D collision shape")

	print("PASS")
	quit(0)


func _collect_mesh_instances(node: Node, out: Array[MeshInstance3D]) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			out.append(child)
		_collect_mesh_instances(child, out)


func _is_inside_console_box(pos: Vector3) -> bool:
	return (
		pos.x >= -3.2 and pos.x <= 3.2
		and pos.y >= 0.0 and pos.y <= 3.3
		and pos.z >= 3.5 and pos.z <= 5.0
	)
