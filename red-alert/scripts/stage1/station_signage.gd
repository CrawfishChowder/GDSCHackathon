class_name StationSignage
extends Node3D

const COLOR_CYAN := Color(0.3, 0.8, 1.0)
const COLOR_RED := Color(1.0, 0.2, 0.2)
const COLOR_CUE := Color(1.0, 0.35, 0.1)

const SIGN_CONFIGS: Array[Dictionary] = [
	{"name": "Sign_o2", "text": "O2 CONTROL", "pos": Vector3(-2.1, 3.02, 4.42), "rot_y": PI, "id": "o2"},
	{"name": "Sign_reactor", "text": "REACTOR", "pos": Vector3(0.0, 3.02, 4.42), "rot_y": PI, "id": "reactor"},
	{"name": "Sign_systems", "text": "CO2 SCRUBBER", "pos": Vector3(2.1, 3.02, 4.42), "rot_y": PI, "id": "co2"},
	{"name": "Sign_power", "text": "POWER BREAKERS", "pos": Vector3(2.8, 2.55, -4.72), "rot_y": 0.0, "id": "power"},
]

const CUE_CONFIGS: Array[Dictionary] = [
	{"name": "Cue_reactor", "pos": Vector3(0.0, 1.75, 3.7), "id": "reactor"},
	{"name": "Cue_o2", "pos": Vector3(-2.13, 1.75, 3.7), "id": "o2"},
	{"name": "Cue_power", "pos": Vector3(2.8, 2.25, -4.45), "id": "power"},
	{"name": "Cue_co2", "pos": Vector3(2.13, 1.75, 3.7), "id": "co2"},
]

var _signs: Array[Dictionary] = []
var _cues: Array[Dictionary] = []
var _time: float = 0.0
var _blink_timer: float = 0.0
var _last_active_id: String = ""


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	_create_signs()
	_create_cues()


func _create_signs() -> void:
	for cfg: Dictionary in SIGN_CONFIGS:
		var label := Label3D.new()
		label.name = cfg["name"]
		label.text = cfg["text"]
		label.font_size = 64
		label.pixel_size = 0.004
		label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		label.outline_size = 12
		label.outline_modulate = Color(0.0, 0.0, 0.0, 1.0)
		label.position = cfg["pos"]
		label.rotation = Vector3(0.0, cfg["rot_y"], 0.0)
		label.modulate = COLOR_CYAN
		add_child(label)
		_signs.append({"node": label, "id": cfg["id"]})


func _create_cues() -> void:
	for cfg: Dictionary in CUE_CONFIGS:
		var cue := Node3D.new()
		cue.name = cfg["name"]
		cue.position = cfg["pos"]
		cue.visible = false

		var light := OmniLight3D.new()
		light.name = "OmniLight3D"
		light.light_color = COLOR_CUE
		light.omni_range = 2.2
		light.light_energy = 0.0
		cue.add_child(light)

		var label := Label3D.new()
		label.name = "Label3D"
		label.text = ">> FIX HERE <<"
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = 48
		label.pixel_size = 0.004
		label.outline_size = 12
		label.outline_modulate = Color(0.0, 0.0, 0.0, 1.0)
		label.modulate = COLOR_CUE
		cue.add_child(label)

		add_child(cue)
		_cues.append({"node": cue, "light": light, "label": label, "id": cfg["id"]})


func _process(delta: float) -> void:
	_time += delta
	_blink_timer += delta

	var mm: Node = get_node_or_null("/root/MalfunctionManager")
	var active_id: String = ""
	if mm != null:
		var raw_id: Variant = mm.get("active_id")
		if raw_id is String:
			active_id = raw_id

	if active_id != _last_active_id:
		_last_active_id = active_id
		_blink_timer = 0.0

	var blink_visible: bool = fposmod(_blink_timer, 0.8) < 0.4
	for s: Dictionary in _signs:
		var sign_node: Label3D = s["node"]
		var id: String = s["id"]
		if id != "" and id == active_id:
			sign_node.modulate = COLOR_RED
			sign_node.visible = blink_visible
		else:
			sign_node.modulate = COLOR_CYAN
			sign_node.visible = true

	var pulse_energy: float = (sin(_time * 6.0) * 0.5 + 0.5) * 2.5
	var bob_y: float = sin(_time * 4.0) * 0.05
	for c: Dictionary in _cues:
		var cue_node: Node3D = c["node"]
		var id: String = c["id"]
		var is_active: bool = (id == active_id and active_id != "")
		cue_node.visible = is_active
		if is_active:
			var light: OmniLight3D = c["light"]
			var label: Label3D = c["label"]
			light.light_energy = pulse_energy
			label.position.y = bob_y
