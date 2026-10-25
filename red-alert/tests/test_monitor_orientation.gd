extends SceneTree

const CONSOLE_SCREENS: Array[NodePath] = [
	NodePath("MainConsole/LeftStation/LeftMonitorScreen"),
	NodePath("MainConsole/CenterStation/PrimaryMonitorScreen"),
	NodePath("MainConsole/RightStation/RightMonitorScreen"),
]
const CONSOLE_IDS: Array[StringName] = [&"console_left", &"console_center", &"console_right"]
const EVENTS: Array[String] = ["o2", "co2", "reactor", "power", "dust_storm"]


func _initialize() -> void:
	await process_frame
	var room_scene := load("res://scenes/stage1/stage_1_room.tscn") as PackedScene
	if room_scene == null:
		return _fail("Stage 1 room did not load")
	var room := room_scene.instantiate()
	root.add_child(room)
	await process_frame
	await process_frame
	var displays := room.get_node("NormalOperations")
	var player := room.get_node("FirstPersonPlayer") as Node3D
	for screen_path in CONSOLE_SCREENS:
		var screen := room.get_node(screen_path) as MeshInstance3D
		if not _faces_player_with_readable_uv(screen, player.global_position):
			return _fail("Console screen faces away or reverses text: %s" % screen_path)
	var manager := root.get_node("MalfunctionManager")
	for event_id in EVENTS:
		manager.call("trigger", event_id)
		await process_frame
		await process_frame
		for monitor_id in CONSOLE_IDS:
			if not displays.call("is_monitor_claimed", monitor_id):
				return _fail("%s emergency screen missing for %s" % [monitor_id, event_id])
		var center_viewport := displays.get_node("Displays/ConsoleCenterViewport") as SubViewport
		var override := center_viewport.get_node("ActiveOverride")
		var event_text := String(manager.call("display_name", event_id)).to_upper()
		var found_event_text := false
		for label in override.find_children("*", "Label", true, false):
			if event_text in (label as Label).text:
				found_event_text = true
		if not found_event_text:
			return _fail("Center emergency screen has no readable %s label" % event_id)
		manager.call("fix", event_id)
		await process_frame
	print("PASS")
	quit(0)


func _faces_player_with_readable_uv(screen: MeshInstance3D, player_position: Vector3) -> bool:
	if screen == null or screen.mesh == null:
		return false
	var material := screen.material_override as StandardMaterial3D
	if material == null:
		return false
	var arrays := screen.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var to_player := (player_position - screen.global_position).normalized()
	var view_forward := -to_player
	var view_right := view_forward.cross(Vector3.UP).normalized()
	var left_projection := INF
	var right_projection := -INF
	var left_u := -1.0
	var right_u := -1.0
	for i in range(vertices.size()):
		var world_normal := (screen.global_transform.basis * normals[i]).normalized()
		if normals[i].z > -0.9 or world_normal.dot(to_player) < 0.4 or vertices[i].y < 0.0:
			continue
		var world_vertex := screen.global_transform * vertices[i]
		var projection := world_vertex.dot(view_right)
		var final_u := uvs[i].x * material.uv1_scale.x + material.uv1_offset.x
		if projection < left_projection:
			left_projection = projection
			left_u = final_u
		if projection > right_projection:
			right_projection = projection
			right_u = final_u
	return absf(left_u) < 0.01 and absf(right_u - 1.0) < 0.01


func _fail(reason: String) -> void:
	print("FAIL: " + reason)
	quit(1)
