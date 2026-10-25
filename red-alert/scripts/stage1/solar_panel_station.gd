# SolarPanelStation: Wall-mounted solar power station for dust storm recovery.
# Houses amber cell indicators, label, and FixStation Area3D for the dust storm minigame.
# Child of WallFixtures on the east wall.
class_name SolarPanelStation
extends Node3D


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS

	# Wall panel (1.2 x 1.0 x 0.12 at local y = 1.5, dark steel)
	var panel_mesh := MeshInstance3D.new()
	panel_mesh.name = "PanelMesh"
	var box := BoxMesh.new()
	box.size = Vector3(1.2, 1.0, 0.12)
	panel_mesh.mesh = box
	panel_mesh.position = Vector3(0.0, 1.5, 0.0)

	var steel_mat := StandardMaterial3D.new()
	steel_mat.albedo_color = Color(0.12, 0.14, 0.16)
	steel_mat.metallic = 0.8
	steel_mat.roughness = 0.4
	panel_mesh.material_override = steel_mat
	add_child(panel_mesh)

	# Three amber "solar cell" strips
	var amber_mat := StandardMaterial3D.new()
	amber_mat.albedo_color = Color(1.0, 0.65, 0.1)
	amber_mat.emission_enabled = true
	amber_mat.emission = Color(1.0, 0.65, 0.1)
	amber_mat.emission_energy_multiplier = 0.8

	var y_offsets: Array[float] = [-0.25, 0.0, 0.25]
	for i in range(3):
		var strip := MeshInstance3D.new()
		strip.name = "SolarCellStrip%d" % (i + 1)
		var strip_box := BoxMesh.new()
		strip_box.size = Vector3(0.9, 0.16, 0.02)
		strip.mesh = strip_box
		strip.position = Vector3(0.0, y_offsets[i], -0.061)
		strip.material_override = amber_mat
		panel_mesh.add_child(strip)

	# Label3D "SOLAR ARRAY" above it (font 64, pixel_size 0.004, cyan)
	var label := Label3D.new()
	label.name = "StationLabel"
	label.text = "SOLAR ARRAY"
	label.font_size = 64
	label.pixel_size = 0.004
	label.modulate = Color(0.3, 0.8, 1.0)
	label.outline_size = 12
	label.outline_modulate = Color.BLACK
	label.position = Vector3(0.0, 2.2, 0.0)
	label.rotation = Vector3.ZERO
	label.double_sided = true
	add_child(label)

	# FixStation Area3D child
	var fix_station_script := load("res://scripts/interaction/fix_station.gd") as GDScript
	if fix_station_script != null:
		var fix_station: Area3D = fix_station_script.new()
		fix_station.name = "FixStation"
		fix_station.position = Vector3(0.0, 1.5, 0.0)
		fix_station.set("malfunction_id", "dust_storm")
		var minigame_res := load("res://scenes/minigames/dust_storm_power.tscn") as PackedScene
		if minigame_res != null:
			fix_station.set("minigame_scene", minigame_res)

		var col := CollisionShape3D.new()
		col.name = "CollisionShape3D"
		var shape := BoxShape3D.new()
		shape.size = Vector3(1.2, 1.0, 0.3)
		col.shape = shape
		fix_station.add_child(col)

		add_child(fix_station)
