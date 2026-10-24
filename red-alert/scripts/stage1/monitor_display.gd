class_name MonitorDisplay
extends Node3D

var viewport: SubViewport
var mesh_instance: MeshInstance3D
var root_control: Control


func _init() -> void:
	process_mode = PROCESS_MODE_ALWAYS


func setup(size_m: Vector2, resolution: Vector2i) -> Control:
	viewport = SubViewport.new()
	viewport.name = "SubViewport"
	viewport.size = resolution
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	viewport.process_mode = PROCESS_MODE_ALWAYS
	add_child(viewport)

	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0.015, 0.025, 0.045, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	viewport.add_child(bg)

	root_control = Control.new()
	root_control.name = "Content"
	root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	viewport.add_child(root_control)

	var quad := QuadMesh.new()
	quad.size = size_m

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_texture = viewport.get_texture()

	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "ScreenMesh"
	mesh_instance.mesh = quad
	mesh_instance.material_override = mat
	add_child(mesh_instance)

	return root_control
