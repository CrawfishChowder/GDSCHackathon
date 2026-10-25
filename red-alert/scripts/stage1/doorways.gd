extends Node3D

var _steel_mat: StandardMaterial3D
var _hazard_yellow_mat: StandardMaterial3D
var _hazard_black_mat: StandardMaterial3D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_materials()
	_build_corridors()


func _create_materials() -> void:
	_steel_mat = StandardMaterial3D.new()
	_steel_mat.albedo_color = Color(0.12, 0.15, 0.18)
	_steel_mat.metallic = 0.85
	_steel_mat.roughness = 0.4

	_hazard_yellow_mat = StandardMaterial3D.new()
	_hazard_yellow_mat.albedo_color = Color(0.9, 0.75, 0.1)
	_hazard_yellow_mat.metallic = 0.2
	_hazard_yellow_mat.roughness = 0.5

	_hazard_black_mat = StandardMaterial3D.new()
	_hazard_black_mat.albedo_color = Color(0.08, 0.08, 0.08)
	_hazard_black_mat.metallic = 0.2
	_hazard_black_mat.roughness = 0.5


func _add_solid_box(
	parent: Node3D, body: StaticBody3D, box_name: String, size: Vector3, pos: Vector3
) -> void:
	var mi := MeshInstance3D.new()
	mi.name = box_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = _steel_mat
	mi.mesh = mesh
	mi.position = pos
	parent.add_child(mi)

	var col := CollisionShape3D.new()
	col.name = box_name + "Shape"
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	col.position = pos
	body.add_child(col)


func _add_light(parent: Node3D, pos: Vector3) -> void:
	var light := OmniLight3D.new()
	light.position = pos
	light.light_color = Color(0.75, 0.9, 1.0)
	light.light_energy = 1.2
	light.omni_range = 4.0
	parent.add_child(light)


func _add_label(parent: Node3D, text: String, pos: Vector3, rot_y: float) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = 72
	label.pixel_size = 0.004
	label.position = pos
	label.rotation.y = rot_y
	label.modulate = Color(0.3, 0.8, 1.0)
	parent.add_child(label)


func _add_stripes(parent: Node3D, start_pos: Vector3, step: Vector3, is_z_axis: bool) -> void:
	var size := Vector3(0.25, 0.01, 0.3) if is_z_axis else Vector3(0.3, 0.01, 0.25)
	for i in range(12):
		var mi := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = size
		mesh.material = _hazard_yellow_mat if i % 2 == 0 else _hazard_black_mat
		mi.mesh = mesh
		mi.position = start_pos + step * float(i)
		parent.add_child(mi)


func _build_corridors() -> void:
	var body := StaticBody3D.new()
	body.name = "CorridorsCollision"
	add_child(body)

	# North corridor (z = -5 to -8, x centered on 0)
	_add_solid_box(self, body, "North_Floor", Vector3(4.0, 0.2, 3.0), Vector3(0.0, -0.1, -6.5))
	_add_solid_box(self, body, "North_Ceiling", Vector3(4.0, 0.2, 3.0), Vector3(0.0, 2.7, -6.5))
	_add_solid_box(self, body, "North_WallW", Vector3(0.2, 2.6, 3.0), Vector3(-1.9, 1.3, -6.5))
	_add_solid_box(self, body, "North_WallE", Vector3(0.2, 2.6, 3.0), Vector3(1.9, 1.3, -6.5))
	_add_solid_box(self, body, "North_WallEnd", Vector3(4.0, 3.0, 0.2), Vector3(0.0, 1.3, -8.1))
	_add_light(self, Vector3(0.0, 2.4, -6.5))
	_add_label(self, "CREW QUARTERS", Vector3(0.0, 1.6, -7.98), 0.0)
	_add_stripes(self, Vector3(-1.65, 0.005, -5.0), Vector3(0.3, 0.0, 0.0), false)

	# East corridor (x = 6 to 9, z centered on 0)
	_add_solid_box(self, body, "East_Floor", Vector3(3.0, 0.2, 4.0), Vector3(7.5, -0.1, 0.0))
	_add_solid_box(self, body, "East_Ceiling", Vector3(3.0, 0.2, 4.0), Vector3(7.5, 2.7, 0.0))
	_add_solid_box(self, body, "East_WallN", Vector3(3.0, 2.6, 0.2), Vector3(7.5, 1.3, -1.9))
	_add_solid_box(self, body, "East_WallS", Vector3(3.0, 2.6, 0.2), Vector3(7.5, 1.3, 1.9))
	_add_solid_box(self, body, "East_WallEnd", Vector3(0.2, 3.0, 4.0), Vector3(9.1, 1.3, 0.0))
	_add_light(self, Vector3(7.5, 2.4, 0.0))
	_add_label(self, "AIRLOCK: EVA PREP", Vector3(8.98, 1.6, 0.0), -PI * 0.5)
	_add_stripes(self, Vector3(6.0, 0.005, -1.65), Vector3(0.0, 0.0, 0.3), true)

	# West corridor (x = -6 to -9, z centered on 0)
	_add_solid_box(self, body, "West_Floor", Vector3(3.0, 0.2, 4.0), Vector3(-7.5, -0.1, 0.0))
	_add_solid_box(self, body, "West_Ceiling", Vector3(3.0, 0.2, 4.0), Vector3(-7.5, 2.7, 0.0))
	_add_solid_box(self, body, "West_WallN", Vector3(3.0, 2.6, 0.2), Vector3(-7.5, 1.3, -1.9))
	_add_solid_box(self, body, "West_WallS", Vector3(3.0, 2.6, 0.2), Vector3(-7.5, 1.3, 1.9))
	_add_solid_box(self, body, "West_WallEnd", Vector3(0.2, 3.0, 4.0), Vector3(-9.1, 1.3, 0.0))
	_add_light(self, Vector3(-7.5, 2.4, 0.0))
	_add_label(self, "GREENHOUSE", Vector3(-8.98, 1.6, 0.0), PI * 0.5)
	_add_stripes(self, Vector3(-6.0, 0.005, -1.65), Vector3(0.0, 0.0, 0.3), true)
