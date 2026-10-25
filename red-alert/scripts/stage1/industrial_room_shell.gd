extends Node3D

const DOOR_OPENING_WIDTH := 3.6
const DOOR_OPENING_HEIGHT := 2.6

@export_category("Room Dimensions")
@export_range(6.0, 30.0, 0.5) var room_width: float = 12.0
@export_range(6.0, 30.0, 0.5) var room_depth: float = 10.0
@export_range(2.5, 8.0, 0.25) var room_height: float = 3.5

var _materials: Dictionary = {}
var _overhead_lights: Array[OmniLight3D] = []
var _light_fixtures: Array[MeshInstance3D] = []
var _light_fixture_material: StandardMaterial3D
var _center_light: OmniLight3D = null


func _ready() -> void:
	_create_materials()
	_build_room()
	var s := get_node_or_null("/root/Settings")
	if s != null and s.has_signal("settings_changed"):
		s.settings_changed.connect(_on_settings_changed)


func _create_materials() -> void:
	_materials["base"] = _metal_material(
		"Dark structural metal", Color("151a20"), 0.9, 0.48
	)
	_materials["panel_dark"] = _metal_material(
		"Dark graphite panel", Color("202731"), 0.82, 0.42
	)
	_materials["panel_mid"] = _metal_material(
		"Medium grey panel", Color("343e49"), 0.78, 0.38
	)
	_materials["beam"] = _metal_material(
		"Reinforced beam", Color("11161c"), 0.92, 0.34
	)
	_materials["light"] = _metal_material(
		"Cold light diffuser", Color("b9d7e8"), 0.15, 0.2, Color("98d7ff")
	)
	_light_fixture_material = _materials["light"] as StandardMaterial3D


func _metal_material(
	resource_name: String,
	color: Color,
	metallic_value: float,
	roughness_value: float,
	emission_color: Color = Color(0.0, 0.0, 0.0, 1.0)
) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.resource_name = resource_name
	material.albedo_color = color
	material.metallic = metallic_value
	material.roughness = roughness_value
	if emission_color.r + emission_color.g + emission_color.b > 0.0:
		material.emission_enabled = true
		material.emission = emission_color
		material.emission_energy_multiplier = 3.2
	return material


func _build_room() -> void:
	var geometry := Node3D.new()
	geometry.name = "GeneratedRoomGeometry"
	add_child(geometry)

	var collision := StaticBody3D.new()
	collision.name = "RoomCollision"
	add_child(collision)

	_build_collision(collision)
	_build_base_shell(geometry)
	_build_floor_panels(geometry)
	_build_wall_panels(geometry)
	_build_structure(geometry)
	_build_lighting(geometry)


func _build_collision(body: StaticBody3D) -> void:
	_add_collision_box(
		body, "FloorCollision", Vector3(room_width, 0.2, room_depth),
		Vector3(0.0, -0.08, 0.0)
	)
	_add_collision_box(
		body, "CeilingCollision", Vector3(room_width, 0.2, room_depth),
		Vector3(0.0, room_height + 0.1, 0.0)
	)
	_add_doorway_wall_collision(
		body, "NorthWallCollision", true, room_width, -room_depth * 0.5 - 0.1
	)
	_add_collision_box(
		body, "SouthWallCollision", Vector3(room_width, room_height, 0.2),
		Vector3(0.0, room_height * 0.5, room_depth * 0.5 + 0.1)
	)
	_add_doorway_wall_collision(
		body, "WestWallCollision", false, room_depth, -room_width * 0.5 - 0.1
	)
	_add_doorway_wall_collision(
		body, "EastWallCollision", false, room_depth, room_width * 0.5 + 0.1
	)


func _build_base_shell(parent: Node3D) -> void:
	_add_box(
		parent, "FloorBase", Vector3(room_width, 0.2, room_depth),
		Vector3(0.0, -0.08, 0.0), _materials["base"]
	)
	_add_box(
		parent, "CeilingBase", Vector3(room_width, 0.2, room_depth),
		Vector3(0.0, room_height + 0.1, 0.0), _materials["base"]
	)
	_add_doorway_wall_base(
		parent, "NorthWallBase", true, room_width, -room_depth * 0.5 - 0.1
	)
	_add_box(
		parent, "SouthWallBase", Vector3(room_width, room_height, 0.2),
		Vector3(0.0, room_height * 0.5, room_depth * 0.5 + 0.1),
		_materials["base"]
	)
	_add_doorway_wall_base(
		parent, "WestWallBase", false, room_depth, -room_width * 0.5 - 0.1
	)
	_add_doorway_wall_base(
		parent, "EastWallBase", false, room_depth, room_width * 0.5 + 0.1
	)


func _add_doorway_wall_collision(
	body: StaticBody3D, base_name: String, is_along_x: bool, wall_length: float, offset: float
) -> void:
	for part in _get_doorway_wall_parts(is_along_x, wall_length, offset):
		_add_collision_box(body, base_name + part["suffix"], part["size"], part["pos"])


func _add_doorway_wall_base(
	parent: Node3D, base_name: String, is_along_x: bool, wall_length: float, offset: float
) -> void:
	for part in _get_doorway_wall_parts(is_along_x, wall_length, offset):
		_add_box(parent, base_name + part["suffix"], part["size"], part["pos"], _materials["base"])


func _get_doorway_wall_parts(
	is_along_x: bool, wall_length: float, offset: float, thickness: float = 0.2
) -> Array[Dictionary]:
	var side_len := (wall_length - DOOR_OPENING_WIDTH) * 0.5
	var header_h := room_height - DOOR_OPENING_HEIGHT
	var header_y := DOOR_OPENING_HEIGHT + header_h * 0.5
	var side_y := room_height * 0.5
	var parts: Array[Dictionary] = []
	if is_along_x:
		parts.append({
			"suffix": "_Left",
			"size": Vector3(side_len, room_height, thickness),
			"pos": Vector3(-wall_length * 0.5 + side_len * 0.5, side_y, offset)
		})
		parts.append({
			"suffix": "_Right",
			"size": Vector3(side_len, room_height, thickness),
			"pos": Vector3(wall_length * 0.5 - side_len * 0.5, side_y, offset)
		})
		parts.append({
			"suffix": "_Header",
			"size": Vector3(DOOR_OPENING_WIDTH, header_h, thickness),
			"pos": Vector3(0.0, header_y, offset)
		})
	else:
		parts.append({
			"suffix": "_Left",
			"size": Vector3(thickness, room_height, side_len),
			"pos": Vector3(offset, side_y, -wall_length * 0.5 + side_len * 0.5)
		})
		parts.append({
			"suffix": "_Right",
			"size": Vector3(thickness, room_height, side_len),
			"pos": Vector3(offset, side_y, wall_length * 0.5 - side_len * 0.5)
		})
		parts.append({
			"suffix": "_Header",
			"size": Vector3(thickness, header_h, DOOR_OPENING_WIDTH),
			"pos": Vector3(offset, header_y, 0.0)
		})
	return parts


func _build_floor_panels(parent: Node3D) -> void:
	var panel_columns := 6
	var panel_rows := 5
	var cell_width := room_width / panel_columns
	var cell_depth := room_depth / panel_rows

	for x_index in range(panel_columns):
		for z_index in range(panel_rows):
			var panel_position := Vector3(
				-room_width * 0.5 + cell_width * (x_index + 0.5),
				0.035,
				-room_depth * 0.5 + cell_depth * (z_index + 0.5)
			)
			var panel_material: Material = (
				_materials["panel_mid"]
				if (x_index + z_index) % 3 == 0
				else _materials["panel_dark"]
			)
			_add_box(
				parent,
				"FloorPanel_%02d_%02d" % [x_index + 1, z_index + 1],
				Vector3(cell_width - 0.08, 0.05, cell_depth - 0.08),
				panel_position,
				panel_material
			)


func _build_wall_panels(parent: Node3D) -> void:
	var vertical_sections := 3
	var panel_height := room_height / vertical_sections
	var north_south_sections := 6
	var north_south_width := room_width / north_south_sections
	var east_west_sections := 5
	var east_west_width := room_depth / east_west_sections

	for side in [-1.0, 1.0]:
		var side_name := "North" if side < 0.0 else "South"
		for horizontal_index in range(north_south_sections):
			var x_pos := -room_width * 0.5 + north_south_width * (horizontal_index + 0.5)
			var half_w := (north_south_width - 0.1) * 0.5
			if side < 0.0 and _overlaps_opening(x_pos, half_w):
				continue
			for vertical_index in range(vertical_sections):
				var panel_material: Material = _wall_panel_material(
					horizontal_index, vertical_index, side > 0.0
				)
				_add_box(
					parent,
					"%sPanel_%02d_%02d" % [
						side_name, horizontal_index + 1, vertical_index + 1
					],
					Vector3(north_south_width - 0.1, panel_height - 0.1, 0.04),
					Vector3(
						x_pos,
						panel_height * (vertical_index + 0.5),
						side * (room_depth * 0.5 - 0.015)
					),
					panel_material
				)

	for side in [-1.0, 1.0]:
		var side_name := "West" if side < 0.0 else "East"
		for horizontal_index in range(east_west_sections):
			var z_pos := -room_depth * 0.5 + east_west_width * (horizontal_index + 0.5)
			var half_d := (east_west_width - 0.1) * 0.5
			if _overlaps_opening(z_pos, half_d):
				continue
			for vertical_index in range(vertical_sections):
				var panel_material: Material = _wall_panel_material(
					horizontal_index, vertical_index, side < 0.0
				)
				_add_box(
					parent,
					"%sPanel_%02d_%02d" % [
						side_name, horizontal_index + 1, vertical_index + 1
					],
					Vector3(0.04, panel_height - 0.1, east_west_width - 0.1),
					Vector3(
						side * (room_width * 0.5 - 0.015),
						panel_height * (vertical_index + 0.5),
						z_pos
					),
					panel_material
				)


func _wall_panel_material(
	horizontal_index: int, vertical_index: int, invert_pattern: bool
) -> Material:
	var pattern_offset := 1 if invert_pattern else 0
	if (horizontal_index + vertical_index + pattern_offset) % 4 == 0:
		return _materials["panel_mid"]
	return _materials["panel_dark"]


func _build_structure(parent: Node3D) -> void:
	var corner_x := room_width * 0.5 - 0.22
	var corner_z := room_depth * 0.5 - 0.22
	for x_side in [-1.0, 1.0]:
		for z_side in [-1.0, 1.0]:
			_add_box(
				parent,
				"CornerPost_%s_%s" % [str(x_side), str(z_side)],
				Vector3(0.34, room_height - 0.12, 0.34),
				Vector3(x_side * corner_x, room_height * 0.5, z_side * corner_z),
				_materials["beam"]
			)

	for z_side in [-1.0, 1.0]:
		_add_box(
			parent, "CeilingBeamZ_%s" % str(z_side),
			Vector3(room_width - 0.45, 0.24, 0.3),
			Vector3(0.0, room_height - 0.16, z_side * corner_z),
			_materials["beam"]
		)
	for x_side in [-1.0, 1.0]:
		_add_box(
			parent, "CeilingBeamX_%s" % str(x_side),
			Vector3(0.3, 0.24, room_depth - 0.45),
			Vector3(x_side * corner_x, room_height - 0.16, 0.0),
			_materials["beam"]
		)

	for x_index in range(1, 6):
		var x_position := -room_width * 0.5 + room_width / 6.0 * x_index
		for z_side in [-1.0, 1.0]:
			if z_side < 0.0 and _overlaps_opening(x_position, 0.045):
				continue
			_add_box(
				parent, "WallRibNS_%02d_%s" % [x_index, str(z_side)],
				Vector3(0.09, room_height - 0.26, 0.12),
				Vector3(x_position, room_height * 0.5, z_side * (room_depth * 0.5 - 0.07)),
				_materials["beam"]
			)

	for z_index in range(1, 5):
		var z_position := -room_depth * 0.5 + room_depth / 5.0 * z_index
		for x_side in [-1.0, 1.0]:
			if _overlaps_opening(z_position, 0.06):
				continue
			_add_box(
				parent, "WallRibEW_%02d_%s" % [z_index, str(x_side)],
				Vector3(0.12, room_height - 0.26, 0.09),
				Vector3(x_side * (room_width * 0.5 - 0.07), room_height * 0.5, z_position),
				_materials["beam"]
			)

	for x_position in [-4.0, 0.0, 4.0]:
		_add_box(
			parent, "CeilingCrossBeam_%s" % str(x_position),
			Vector3(0.18, 0.18, room_depth - 0.65),
			Vector3(x_position, room_height - 0.12, 0.0),
			_materials["beam"]
		)


func _overlaps_opening(pos: float, half_extent: float) -> bool:
	var open_half := DOOR_OPENING_WIDTH * 0.5
	return (pos + half_extent > -open_half) and (pos - half_extent < open_half)


func _build_lighting(parent: Node3D) -> void:
	for row_index in range(3):
		var z_position := -3.0 + row_index * 3.0
		for column_index in range(3):
			var x_position := -3.6 + column_index * 3.6
			var fixture := _add_box(
				parent,
				"LightFixture_%02d_%02d" % [row_index + 1, column_index + 1],
				Vector3(2.15, 0.1, 0.42),
				Vector3(x_position, room_height - 0.24, z_position),
				_materials["light"]
			)
			_light_fixtures.append(fixture)
			var light := OmniLight3D.new()
			light.name = "ColdOverheadLight_%02d_%02d" % [
				row_index + 1, column_index + 1
			]
			light.position = Vector3(x_position, room_height - 0.38, z_position)
			light.light_color = Color("b9e3ff")
			light.light_energy = 5.5
			light.omni_range = 6.5
			light.omni_attenuation = 1.1
			# Only the center light casts shadows: nine shadowed omni lights cost a lot
			# of frame time in the Compatibility renderer (playtest: mouse lag).
			if row_index == 1 and column_index == 1:
				_center_light = light
				light.shadow_enabled = _get_shadows_enabled()
			else:
				light.shadow_enabled = false
			parent.add_child(light)
			_overhead_lights.append(light)


func _get_shadows_enabled() -> bool:
	var s := get_node_or_null("/root/Settings")
	if s != null and s.has_method("get_setting"):
		var v: Variant = s.get_setting("shadows")
		if v != null:
			return bool(v)
	return true


func _on_settings_changed(key: String, value: Variant) -> void:
	if key == "shadows" and is_instance_valid(_center_light):
		_center_light.shadow_enabled = bool(value)


func set_alert_lighting(is_on: bool) -> void:
	for light in _overhead_lights:
		light.light_color = Color("ff1717")
		light.light_energy = 5.5 if is_on else 0.0

	_light_fixture_material.albedo_color = (
		Color("ff3030") if is_on else Color("201010")
	)
	_light_fixture_material.emission = Color("ff0909") if is_on else Color.BLACK
	_light_fixture_material.emission_energy_multiplier = 3.2 if is_on else 0.0


func restore_overhead_lighting() -> void:
	for light in _overhead_lights:
		light.light_color = Color("b9e3ff")
		light.light_energy = 5.5

	_light_fixture_material.albedo_color = Color("b9d7e8")
	_light_fixture_material.emission = Color("98d7ff")
	_light_fixture_material.emission_energy_multiplier = 3.2


func _add_box(
	parent: Node,
	node_name: String,
	size: Vector3,
	box_position: Vector3,
	material: Material
) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	mesh_instance.mesh = mesh
	mesh_instance.position = box_position
	parent.add_child(mesh_instance)
	return mesh_instance


func _add_collision_box(
	parent: StaticBody3D, node_name: String, size: Vector3, box_position: Vector3
) -> void:
	var shape := BoxShape3D.new()
	shape.size = size
	var collision_shape := CollisionShape3D.new()
	collision_shape.name = node_name
	collision_shape.shape = shape
	collision_shape.position = box_position
	parent.add_child(collision_shape)
