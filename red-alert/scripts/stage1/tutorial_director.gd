extends Node

const PREFIX := "TRAINING (no countdown): "
const PROXIMITY_DISTANCE := 2.2

var _step: int = 0
var _active: bool = false
var _start_timer: float = 6.0
var _complete_timer: float = 0.0

var _layer: CanvasLayer
var _panel: PanelContainer
var _label: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_ui()
	_connect_signals()
	_check_activation()

func _process(delta: float) -> void:
	if not _active: return
	if _step == 4:
		if _complete_timer > 0.0:
			_complete_timer -= delta
			if _complete_timer <= 0.0 and _panel != null: _panel.visible = false
	elif _step == 0:
		_start_timer -= delta
		if _start_timer <= 0.0: _start_tutorial()
	elif _step == 1:
		if _minigame_is_open():
			_advance_to(3, "Type the filter code, then press ENTER. One wrong digit is fatal.", "crew_tutorial_3")
		else:
			var player := _get_target("FirstPersonPlayer", "FirstPersonPlayer")
			var station := _get_target("MainConsole/LeftStation/O2Station", "O2Station")
			if player != null and station != null and player.global_position.distance_to(station.global_position) <= PROXIMITY_DISTANCE:
				_advance_to(2, "Look at the keyboard and press E", "crew_tutorial_2")
	elif _step == 2 and _minigame_is_open():
		_advance_to(3, "Type the filter code, then press ENTER. One wrong digit is fatal.", "crew_tutorial_3")

func current_step() -> int:
	return _step

func _check_activation() -> void:
	var sd := _get_node("SaveData")
	var mm := _get_node("MalfunctionManager")
	var is_done: bool = bool(sd.call("get_value", "tutorial_done", false)) if sd != null else false
	var is_practice: bool = (String(mm.get("mode")) == "practice") if mm != null else false
	_active = not is_done or is_practice

func _connect_signals() -> void:
	var mm := _get_node("MalfunctionManager")
	if mm != null:
		if not mm.is_connected("malfunction_fixed", _on_malfunction_fixed):
			mm.connect("malfunction_fixed", _on_malfunction_fixed)
		if not mm.is_connected("player_died", _on_player_died):
			mm.connect("player_died", _on_player_died)

func _start_tutorial() -> void:
	var mm := _get_node("MalfunctionManager")
	if mm != null:
		if not bool(mm.get("running")): mm.call("start_run")
		mm.call("trigger", "o2")
		mm.set("countdown_frozen", true)
	_advance_to(1, "Follow the >> FIX HERE << marker to the LEFT CONSOLE", "crew_tutorial_1")

func _advance_to(step: int, text: String, voice_id: String) -> void:
	_step = step
	_update_banner(PREFIX + text)
	var v := _get_node("Voice")
	if v != null: v.call("say", voice_id)

func _on_malfunction_fixed(id: String) -> void:
	if id != "o2" or _step < 1 or _step >= 4: return
	_step = 4
	var mm := _get_node("MalfunctionManager")
	if mm != null: mm.set("countdown_frozen", false)
	var sd := _get_node("SaveData")
	if sd != null: sd.call("set_value", "tutorial_done", true)
	_update_banner("Training complete. Every failure from now on has a countdown.")
	var voice := _get_node("Voice")
	if voice != null: voice.call("say", "crew_tutorial_done")
	_complete_timer = 4.0

func _on_player_died(_cause_id: String, _display_name: String) -> void:
	var mm := _get_node("MalfunctionManager")
	if mm != null: mm.set("countdown_frozen", false)
	if _panel != null: _panel.visible = false
	_step = 0
	_active = false

func _setup_ui() -> void:
	_layer = CanvasLayer.new()
	_layer.name = "TutorialObjectiveLayer"
	_layer.layer = 11
	_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_layer)

	_panel = PanelContainer.new()
	_panel.name = "ObjectiveBanner"
	_panel.anchors_preset = Control.PRESET_CENTER_TOP
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.offset_left = -420.0
	_panel.offset_top = 74.0
	_panel.offset_right = 420.0
	_panel.offset_bottom = 126.0
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.visible = false

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.06, 0.08, 0.95)
	style.set_border_width_all(2)
	style.border_color = Color(0.3, 0.8, 1.0)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10.0)
	_panel.add_theme_stylebox_override("panel", style)
	_layer.add_child(_panel)

	_label = Label.new()
	_label.name = "ObjectiveLabel"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override("font_size", 22)
	_label.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
	_panel.add_child(_label)

func _update_banner(text: String) -> void:
	if _label != null: _label.text = text
	if _panel != null: _panel.visible = true

func _minigame_is_open() -> bool:
	var mh := _get_node("MinigameHost")
	return mh != null and mh.has_method("is_open") and bool(mh.call("is_open"))

func _get_target(path: String, child_name: String) -> Node3D:
	var p := get_parent()
	if p == null: return null
	var n := p.get_node_or_null(path) as Node3D
	return n if n != null else p.find_child(child_name, true, false) as Node3D

func _get_node(node_name: String) -> Node:
	return get_node_or_null("/root/" + node_name) if is_inside_tree() else null
