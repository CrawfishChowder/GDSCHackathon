extends Node

const MATRIX_DISPLAY_SCENE: PackedScene = preload(
	"res://scenes/displays/matrix_display.tscn"
)
const TBD_BOUNCE_DISPLAY_SCENE: PackedScene = preload(
	"res://scenes/displays/tbd_bounce_display.tscn"
)

const MONITOR_DEFINITIONS: Array[Dictionary] = [
	{
		"id": &"console_left",
		"path": NodePath("MainConsole/LeftStation/LeftMonitorScreen"),
		"default_scene": MATRIX_DISPLAY_SCENE,
		"seed": 1103,
		"speed": 0.82,
		"visible_face": -1,
	},
	{
		"id": &"console_center",
		"path": NodePath("MainConsole/CenterStation/PrimaryMonitorScreen"),
		"default_scene": MATRIX_DISPLAY_SCENE,
		"seed": 2207,
		"speed": 1.0,
		"visible_face": -1,
	},
	{
		"id": &"console_right",
		"path": NodePath("MainConsole/RightStation/RightMonitorScreen"),
		"default_scene": MATRIX_DISPLAY_SCENE,
		"seed": 3301,
		"speed": 1.2,
		"visible_face": -1,
	},
	{
		"id": &"door_north",
		"path": NodePath("BulkheadDoors/NorthBulkheadDoor/LeftAccessMonitor/Screen"),
		"default_scene": TBD_BOUNCE_DISPLAY_SCENE,
		"seed": 4409,
		"speed": 0.9,
		"color": 0,
		"visible_face": 1,
	},
	{
		"id": &"door_east",
		"path": NodePath("BulkheadDoors/EastBulkheadDoor/LeftAccessMonitor/Screen"),
		"default_scene": TBD_BOUNCE_DISPLAY_SCENE,
		"seed": 5501,
		"speed": 1.08,
		"color": 2,
		"visible_face": 1,
	},
	{
		"id": &"door_west",
		"path": NodePath("BulkheadDoors/WestBulkheadDoor/LeftAccessMonitor/Screen"),
		"default_scene": TBD_BOUNCE_DISPLAY_SCENE,
		"seed": 6607,
		"speed": 1.22,
		"color": 4,
		"visible_face": 1,
	},
]

@export_range(128, 1024, 16) var render_height: int = 360

@onready var displays: Node = $Displays

var _slots: Dictionary = {}
var _connected_owner_ids: Dictionary = {}


func _ready() -> void:
	_initialize_monitors()


func _exit_tree() -> void:
	for slot: Dictionary in _slots.values():
		var surface := slot["surface"] as MeshInstance3D
		if is_instance_valid(surface):
			surface.material_override = slot["original_material"]


## Claims one monitor for owner and places display_scene above its running default.
## Returns false for an unknown ID, invalid display, or ownership conflict.
func claim_monitor(
	monitor_id: StringName, requester: Node, display_scene: PackedScene
) -> bool:
	var slot := _get_slot(monitor_id)
	if slot.is_empty():
		return false
	if requester == null or not is_instance_valid(requester) or not requester.is_inside_tree():
		push_warning("Monitor '%s' requires an owner that is in the scene tree." % monitor_id)
		return false
	if display_scene == null:
		push_warning("Monitor '%s' was given an empty display scene." % monitor_id)
		return false

	var owner_id := requester.get_instance_id()
	var current_owner_id: int = slot["owner_id"]
	if current_owner_id != 0 and current_owner_id != owner_id:
		push_warning(
			"Monitor '%s' is already claimed; request from '%s' was rejected."
			% [monitor_id, requester.name]
		)
		return false

	var supplied_display := display_scene.instantiate()
	if not supplied_display is CanvasItem:
		push_warning("Monitor override scenes must have a Control or Node2D root.")
		supplied_display.free()
		return false

	_clear_override(slot)
	var viewport := slot["viewport"] as SubViewport
	var override_layer := _create_override_layer(viewport, supplied_display)
	slot["override_layer"] = override_layer
	slot["owner_id"] = owner_id
	_connect_owner(requester)
	return true


## Releases one monitor. Only its current owner may release it.
func release_monitor(monitor_id: StringName, requester: Node) -> bool:
	var slot := _get_slot(monitor_id)
	if slot.is_empty():
		return false
	if slot["owner_id"] == 0:
		return true
	if requester == null or not is_instance_valid(requester):
		return false
	if slot["owner_id"] != requester.get_instance_id():
		push_warning("Only the current owner may release monitor '%s'." % monitor_id)
		return false

	_clear_override(slot)
	return true


## Releases every monitor currently held by owner.
func release_all(requester: Node) -> void:
	if requester == null or not is_instance_valid(requester):
		return
	_release_by_owner_id(requester.get_instance_id())


func is_monitor_claimed(monitor_id: StringName) -> bool:
	var slot := _get_slot(monitor_id)
	return not slot.is_empty() and slot["owner_id"] != 0


func get_monitor_ids() -> Array[StringName]:
	var monitor_ids: Array[StringName] = []
	for definition in MONITOR_DEFINITIONS:
		monitor_ids.append(definition["id"])
	return monitor_ids


func get_monitor_resolution(monitor_id: StringName) -> Vector2i:
	var slot := _get_slot(monitor_id)
	if slot.is_empty():
		return Vector2i.ZERO
	return (slot["viewport"] as SubViewport).size


func _initialize_monitors() -> void:
	var room := get_parent()
	for definition in MONITOR_DEFINITIONS:
		var monitor_id: StringName = definition["id"]
		var surface := room.get_node_or_null(definition["path"]) as MeshInstance3D
		if surface == null or surface.mesh == null:
			push_error(
				"Normal Operations could not find monitor '%s' at %s."
				% [monitor_id, definition["path"]]
			)
			continue

		var resolution := _resolution_for_surface(surface)
		var viewport := SubViewport.new()
		viewport.name = "%sViewport" % _pascal_case(String(monitor_id))
		viewport.size = resolution
		viewport.disable_3d = true
		viewport.transparent_bg = false
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		displays.add_child(viewport)

		var default_display := (
			definition["default_scene"] as PackedScene
		).instantiate() as CanvasItem
		default_display.set("random_seed", definition["seed"])
		default_display.set("speed_scale", definition["speed"])
		if definition.has("color"):
			default_display.set("initial_color_index", definition["color"])
		_fit_canvas_item(default_display, resolution)
		viewport.add_child(default_display)

		var source_material := surface.get_active_material(0) as StandardMaterial3D
		var screen_material := (
			source_material.duplicate() as StandardMaterial3D
			if source_material != null
			else StandardMaterial3D.new()
		)
		screen_material.resource_name = "%s live display" % monitor_id
		screen_material.albedo_color = Color.WHITE
		screen_material.albedo_texture = viewport.get_texture()
		screen_material.emission_enabled = true
		screen_material.emission = Color.WHITE
		screen_material.emission_texture = viewport.get_texture()
		screen_material.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
		screen_material.emission_energy_multiplier = 1.15
		screen_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
		screen_material.texture_repeat = false
		if definition["visible_face"] < 0:
			screen_material.metallic = 0.02
			screen_material.roughness = 0.82
			screen_material.metallic_specular = 0.08
			screen_material.uv1_scale = Vector3(-3.0, 2.0, 1.0)
			screen_material.uv1_offset = Vector3(3.0, 0.0, 0.0)
		else:
			screen_material.uv1_scale = Vector3(3.0, 2.0, 1.0)
			screen_material.uv1_offset = Vector3.ZERO

		var slot: Dictionary = {
			"surface": surface,
			"viewport": viewport,
			"default_display": default_display,
			"original_material": surface.material_override,
			"owner_id": 0,
			"override_layer": null,
		}
		_slots[monitor_id] = slot
		surface.set_meta(&"monitor_id", monitor_id)
		surface.material_override = screen_material


func _resolution_for_surface(surface: MeshInstance3D) -> Vector2i:
	var mesh_size := surface.mesh.get_aabb().size
	var global_basis := surface.global_transform.basis
	var physical_width := mesh_size.x * global_basis.x.length()
	var physical_height := mesh_size.y * global_basis.y.length()
	var aspect_ratio := physical_width / maxf(physical_height, 0.001)
	return Vector2i(maxi(128, int(round(render_height * aspect_ratio))), render_height)


func _create_override_layer(
	viewport: SubViewport, supplied_display: CanvasItem
) -> Control:
	var layer := Control.new()
	layer.name = "ActiveOverride"
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fit_canvas_item(layer, viewport.size)
	viewport.add_child(layer)

	var backdrop := ColorRect.new()
	backdrop.name = "OpaqueBackdrop"
	backdrop.color = Color.BLACK
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fit_canvas_item(backdrop, viewport.size)
	layer.add_child(backdrop)

	_fit_canvas_item(supplied_display, viewport.size)
	layer.add_child(supplied_display)
	return layer


func _fit_canvas_item(item: CanvasItem, resolution: Vector2i) -> void:
	if item is Control:
		var control := item as Control
		control.set_anchors_preset(Control.PRESET_TOP_LEFT)
		control.position = Vector2.ZERO
		control.size = Vector2(resolution)


func _clear_override(slot: Dictionary) -> void:
	var override_layer := slot["override_layer"] as Control
	if is_instance_valid(override_layer):
		override_layer.get_parent().remove_child(override_layer)
		override_layer.queue_free()
	slot["override_layer"] = null
	slot["owner_id"] = 0


func _connect_owner(requester: Node) -> void:
	var owner_id := requester.get_instance_id()
	if _connected_owner_ids.has(owner_id):
		return
	_connected_owner_ids[owner_id] = true
	requester.tree_exiting.connect(
		_on_owner_tree_exiting.bind(owner_id), CONNECT_ONE_SHOT
	)


func _on_owner_tree_exiting(owner_id: int) -> void:
	_release_by_owner_id(owner_id)
	_connected_owner_ids.erase(owner_id)


func _release_by_owner_id(owner_id: int) -> void:
	for slot: Dictionary in _slots.values():
		if slot["owner_id"] == owner_id:
			_clear_override(slot)


func _get_slot(monitor_id: StringName) -> Dictionary:
	if not _slots.has(monitor_id):
		push_warning("Unknown monitor ID: '%s'." % monitor_id)
		return {}
	return _slots[monitor_id]


func _pascal_case(value: String) -> String:
	var result := ""
	for part in value.split("_", false):
		result += part.capitalize()
	return result
