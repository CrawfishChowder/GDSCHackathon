# RoomProps: Procedural decor generator for the habitat interior.
# Builds conduits, ceiling vents, storage lockers, cable trays, and hazard stripes.
# Static visual node instantiated under Polish/RoomProps.
extends Node3D

var _mat_cache: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_pipes()
	_build_vents()
	_build_storage()
	_build_cable_trays()
	_build_hazard_stripes()


func _get_mat(color: Color, metallic: float = 0.85, roughness: float = 0.4, emission: Color = Color.BLACK) -> StandardMaterial3D:
	var key := "%s_%.2f_%.2f_%s" % [color.to_html(), metallic, roughness, emission.to_html()]
	if _mat_cache.has(key):
		return _mat_cache[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metallic
	mat.roughness = roughness
	if emission.r + emission.g + emission.b > 0.0:
		mat.emission_enabled = true
		mat.emission = emission
	_mat_cache[key] = mat
	return mat


func _box(p_name: String, size: Vector3, pos: Vector3, color: Color, collide: bool = false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = p_name
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.position = pos
	mi.material_override = _get_mat(color)
	add_child(mi)
	if collide:
		var sb := StaticBody3D.new()
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		col.shape = shape
		sb.add_child(col)
		mi.add_child(sb)
	return mi


func _build_pipes() -> void:
	var insets: Array[float] = [0.18, 0.25, 0.32]
	var radii: Array[float] = [0.06, 0.08, 0.10]
	var pipe_color := Color(0.2, 0.23, 0.27)
	var bracket_color := Color(0.12, 0.15, 0.18)
	var z_spans: Array[Vector2] = [Vector2(-4.6, -1.9), Vector2(1.9, 4.6)]
	var bracket_zs: Array[float] = [-4.5, -3.0, 3.0, 4.5]

	for wall_sign in [-1.0, 1.0]:
		var wall_x: float = wall_sign * 6.0
		var side_name: String = "E"
		if wall_sign < 0.0:
			side_name = "W"
		for i in range(3):
			var px: float = wall_x - wall_sign * insets[i]
			var radius: float = radii[i]
			for s in range(z_spans.size()):
				var z_start: float = z_spans[s].x
				var z_end: float = z_spans[s].y
				var length: float = absf(z_end - z_start)
				var center_z: float = (z_start + z_end) * 0.5
				var mi := MeshInstance3D.new()
				mi.name = "Pipe_%s_%d_%d" % [side_name, i, s]
				var cyl := CylinderMesh.new()
				cyl.top_radius = radius
				cyl.bottom_radius = radius
				cyl.height = length
				mi.mesh = cyl
				mi.position = Vector3(px, 3.25, center_z)
				mi.rotation.x = PI * 0.5
				mi.material_override = _get_mat(pipe_color)
				add_child(mi)

			for bz in bracket_zs:
				_box("Bracket_%s_%d_%.1f" % [side_name, i, bz], Vector3(0.04, 0.25, 0.08), Vector3(px, 3.375, bz), bracket_color)


func _build_vents() -> void:
	var dark_steel := Color(0.12, 0.15, 0.18)
	var slat_color := Color(0.06, 0.08, 0.10)
	var vent_coords: Array[Vector3] = [
		Vector3(-4.6, 2.6, 4.96), Vector3(4.6, 2.6, 4.96),
		Vector3(-4.6, 2.6, -4.96), Vector3(4.6, 2.6, -4.96)
	]
	for v in range(vent_coords.size()):
		var vc: Vector3 = vent_coords[v]
		_box("VentFrame_%d" % v, Vector3(0.6, 0.35, 0.04), vc, dark_steel)
		var z_dir: float = 1.0
		if vc.z > 0.0:
			z_dir = -1.0
		for s in range(5):
			var sy: float = vc.y - 0.12 + float(s) * 0.06
			var sz: float = vc.z + z_dir * 0.02
			_box("VentSlat_%d_%d" % [v, s], Vector3(0.52, 0.025, 0.02), Vector3(vc.x, sy, sz), slat_color)


func _build_storage() -> void:
	var locker_color := Color(0.12, 0.15, 0.18)
	var handle_color := Color(0.45, 0.5, 0.55)
	var cyan_accent := Color(0.3, 0.8, 1.0)
	var z_positions: Array[float] = [3.2, 4.0]
	for idx in range(z_positions.size()):
		var lz: float = z_positions[idx]
		_box("Locker_%d" % idx, Vector3(0.5, 2.0, 0.6), Vector3(-5.6, 1.0, lz), locker_color, true)
		_box("LockerHandle_%d" % idx, Vector3(0.02, 0.25, 0.03), Vector3(-5.34, 1.0, lz + 0.18), handle_color)
		var strip := _box("LockerStrip_%d" % idx, Vector3(0.01, 0.03, 0.2), Vector3(-5.34, 1.85, lz), cyan_accent)
		strip.material_override = _get_mat(cyan_accent, 0.2, 0.2, cyan_accent)
		var label := Label3D.new()
		label.text = "SECURE"
		label.pixel_size = 0.001
		label.position = Vector3(-5.33, 1.85, lz)
		label.rotation.y = PI * 0.5
		label.font_size = 28
		add_child(label)


func _build_cable_trays() -> void:
	var tray_color := Color(0.16, 0.19, 0.22)
	_box("CableTray_NW", Vector3(3.3, 0.06, 0.3), Vector3(-3.85, 2.9, -4.85), tray_color)
	_box("CableTray_NE", Vector3(3.3, 0.06, 0.3), Vector3(3.85, 2.9, -4.85), tray_color)


func _build_hazard_stripes() -> void:
	var yellow := Color(0.95, 0.8, 0.0)
	var black := Color(0.08, 0.08, 0.08)
	for i in range(8):
		for j in range(8):
			if i != 0 and i != 7 and j != 0 and j != 7:
				continue
			var px: float = 4.275 + float(i) * 0.15
			var pz: float = 3.275 + float(j) * 0.15
			var c: Color = black
			if (i + j) % 2 == 0:
				c = yellow
			_box("HazardStripe_%d_%d" % [i, j], Vector3(0.15, 0.01, 0.15), Vector3(px, 0.005, pz), c)
