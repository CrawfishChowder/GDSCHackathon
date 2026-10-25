extends SceneTree

var _got := {}


func _fail(reason: String) -> void:
	print("FAIL: " + reason)
	quit(1)


func _initialize() -> void:
	await process_frame

	if root.get_node_or_null("SaveData") == null:
		var sd_script = load("res://scripts/systems/save_data.gd")
		if sd_script != null:
			var sd: Node = sd_script.new()
			sd.name = "SaveData"
			root.add_child(sd)
	if root.get_node_or_null("MalfunctionManager") == null:
		var mm_script = load("res://scripts/systems/malfunction_manager.gd")
		if mm_script != null:
			var mm: Node = mm_script.new()
			mm.name = "MalfunctionManager"
			root.add_child(mm)

	var room_scene := load("res://scenes/stage1/stage_1_room.tscn") as PackedScene
	if room_scene == null:
		return _fail("Failed to load stage_1_room.tscn")

	var room: Node = room_scene.instantiate()
	root.add_child(room)

	await process_frame
	await process_frame

	var center_display: Node = room.get_node_or_null("MainConsole/ConsoleDisplays/CenterDisplay")
	if center_display == null:
		return _fail("CenterDisplay not found at MainConsole/ConsoleDisplays/CenterDisplay")

	var mesh_node: MeshInstance3D = center_display.get_node_or_null("ScreenMesh") as MeshInstance3D
	if mesh_node == null and "mesh_instance" in center_display:
		mesh_node = center_display.get("mesh_instance") as MeshInstance3D
	if mesh_node == null:
		return _fail("ScreenMesh not found on CenterDisplay")

	var mat: Material = mesh_node.material_override
	if mat == null:
		mat = mesh_node.get_active_material(0)
	if mat == null and mesh_node.mesh != null:
		mat = mesh_node.mesh.material
	if mat == null:
		return _fail("No material found on CenterDisplay ScreenMesh")

	if not (mat is ShaderMaterial):
		return _fail("Expected ShaderMaterial on CenterDisplay mesh, got %s" % mat.get_class())

	var sm := mat as ShaderMaterial
	var screen_tex = sm.get_shader_parameter("screen_tex")
	if screen_tex == null:
		return _fail("ShaderMaterial does not have screen_tex parameter set")

	var o2_scene := load("res://scenes/minigames/o2_keypad.tscn") as PackedScene
	if o2_scene == null:
		return _fail("Failed to load o2_keypad.tscn")

	var o2: Node = o2_scene.instantiate()
	root.add_child(o2)

	await create_timer(0.3, true).timeout

	var panel: Control = o2.get_node_or_null("MinigamePanel") as Control
	if panel == null:
		return _fail("MinigamePanel not found in O2 keypad")

	var alpha: float = panel.modulate.a
	if alpha < 0.99:
		return _fail("Expected panel modulate.a >= 0.99 (1.0 within 0.01), got %f" % alpha)

	room.queue_free()
	o2.queue_free()
	await process_frame

	print("PASS")
	quit(0)
