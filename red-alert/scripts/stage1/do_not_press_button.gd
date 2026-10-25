# DoNotPressButton: Pedestal button tempting the player to cause an instant failure.
# Tracks press count via SaveData, plays HAL voice lines, and triggers death after a 2-second delay.
# Interactable via interactor.gd (press E).
extends Node3D

var prompt_text: String = "DO NOT PRESS"
var enabled: bool = true

var _button_mesh: MeshInstance3D = null
var _count_label: Label3D = null


func _ready() -> void:
	_build_components()
	var sd: Node = get_node_or_null("/root/SaveData") if is_inside_tree() else null
	var initial_count: int = 0
	if sd != null and sd.has_method("get_value"):
		initial_count = int(sd.call("get_value", "do_not_press_count", 0))
	_update_count_label(initial_count)


# Called when player presses interact (E); sounds alarm, increments count, and delays fatal kill.
func interact(_by: Node = null) -> void:
	if not enabled:
		return
	enabled = false

	var sfx: Node = get_node_or_null("/root/Sfx") if is_inside_tree() else null
	if sfx != null and sfx.has_method("play"):
		sfx.play("clunk", global_position)
		var tree := get_tree()
		if tree != null:
			tree.create_timer(0.3, true, false, true).timeout.connect(func() -> void:
				if not is_instance_valid(self) or not is_inside_tree():
					return
				var sfx2: Node = get_node_or_null("/root/Sfx") if is_inside_tree() else null
				if sfx2 != null and sfx2.has_method("play"):
					sfx2.play("siren")
			)
		else:
			sfx.play("siren")

	if _button_mesh != null and is_instance_valid(_button_mesh):
		var tween := create_tween()
		if tween != null:
			tween.tween_property(_button_mesh, "position:y", _button_mesh.position.y - 0.03, 0.15)

	var sd: Node = get_node_or_null("/root/SaveData") if is_inside_tree() else null
	var count: int = 1
	if sd != null and sd.has_method("increment"):
		count = int(sd.call("increment", "do_not_press_count"))
	_update_count_label(count)

	var voice: Node = get_node_or_null("/root/Voice") if is_inside_tree() else null
	if voice != null and voice.has_method("say"):
		voice.call("say", "hal_button_%d" % mini(count, 3))

	var tree := get_tree()
	if tree == null:
		return
	await tree.create_timer(2.0, true, false, true).timeout
	if not is_instance_valid(self) or not is_inside_tree():
		return

	var mm: Node = get_node_or_null("/root/MalfunctionManager") if is_inside_tree() else null
	if mm != null and mm.has_method("kill"):
		mm.call("kill", "do_not_press", "button", "You pressed the button. Total presses on record: %d." % count)


func _update_count_label(count: int) -> void:
	if _count_label == null:
		return
	if count > 0:
		_count_label.text = "Pressed %d times" % count
		_count_label.visible = true
	else:
		_count_label.visible = false


func _build_components() -> void:
	var body := StaticBody3D.new()
	body.name = "CollisionBody"
	body.collision_layer = 3
	var col_shape := CollisionShape3D.new()
	col_shape.name = "CollisionShape3D"
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(0.5, 1.1, 0.5)
	col_shape.shape = box_shape
	col_shape.position = Vector3(0.0, 0.55, 0.0)
	body.add_child(col_shape)
	add_child(body)

	var pedestal := MeshInstance3D.new()
	pedestal.name = "Pedestal"
	var pedestal_mesh := BoxMesh.new()
	pedestal_mesh.size = Vector3(0.45, 1.0, 0.45)
	var pedestal_mat := StandardMaterial3D.new()
	pedestal_mat.albedo_color = Color(0.2, 0.17, 0.02)
	pedestal_mesh.material = pedestal_mat
	pedestal.mesh = pedestal_mesh
	pedestal.position = Vector3(0.0, 0.5, 0.0)
	add_child(pedestal)

	_button_mesh = MeshInstance3D.new()
	_button_mesh.name = "ButtonMesh"
	var cyl_mesh := CylinderMesh.new()
	cyl_mesh.top_radius = 0.12
	cyl_mesh.bottom_radius = 0.12
	cyl_mesh.height = 0.08
	var button_mat := StandardMaterial3D.new()
	button_mat.albedo_color = Color(0.9, 0.08, 0.08)
	button_mat.emission_enabled = true
	button_mat.emission = Color(1.0, 0.1, 0.1)
	button_mat.emission_energy_multiplier = 2.0
	cyl_mesh.material = button_mat
	_button_mesh.mesh = cyl_mesh
	_button_mesh.position = Vector3(0.0, 1.04, 0.0)
	add_child(_button_mesh)

	var title_label := Label3D.new()
	title_label.name = "TitleLabel"
	title_label.text = "DO NOT PRESS"
	title_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title_label.font_size = 48
	title_label.modulate = Color(1.0, 0.15, 0.15)
	title_label.position = Vector3(0.0, 1.45, 0.0)
	add_child(title_label)

	_count_label = Label3D.new()
	_count_label.name = "CountLabel"
	_count_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_count_label.font_size = 28
	_count_label.modulate = Color(0.65, 0.65, 0.65)
	_count_label.position = Vector3(0.0, 1.3, 0.0)
	add_child(_count_label)
