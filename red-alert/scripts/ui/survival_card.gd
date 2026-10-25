class_name SurvivalCard
extends CanvasLayer
# SurvivalCard displays real-world spaceflight success stories upon fixing a malfunction.
# Also shows a cautionary warning card when making a mistake in Practice mode.

const CYAN_ACCENT := Color(0.3, 0.8, 1.0)
const RED_ACCENT := Color(0.9, 0.2, 0.2)

const SURVIVAL_CARDS := {
	"reactor": [
		{
			"title": "Kilopower KRUSTY test (2018)",
			"story": "NASA and the Department of Energy ran a small fission reactor at full power for 28 hours in Nevada, a step toward powering future bases on Mars."
		},
		{
			"title": "ISS ammonia leak (2013)",
			"story": "When the International Space Station began leaking ammonia coolant, astronauts Chris Cassidy and Tom Marshburn made an unplanned spacewalk to replace a suspect pump controller box."
		},
	],
	"power": [
		{
			"title": "Apollo 12 (1969)",
			"story": "Lightning struck Apollo 12 twice during launch and knocked its fuel cells offline. Flight controller John Aaron called \"SCE to AUX\", the crew flipped one obscure switch, and the mission flew on."
		},
		{
			"title": "Skylab (1973)",
			"story": "During launch, Skylab's micrometeoroid shield tore away, taking one solar wing and jamming the other. The first crew deployed a parasol sunshade and freed the jammed solar wing on a spacewalk, saving the station."
		},
	],
	"o2": [
		{
			"title": "Apollo 13 (1970)",
			"story": "An oxygen tank exploded on the way to the Moon. The crew used the lunar module as a lifeboat for nearly four days and made it home."
		},
		{
			"title": "Mir fire (1997)",
			"story": "An oxygen-generating canister caught fire aboard the Mir space station. The crew put on masks, fought the fire with extinguishers and kept the station habitable."
		},
	],
	"co2": [
		{
			"title": "Apollo 13 scrubber adapter (1970)",
			"story": "With carbon dioxide rising, engineers improvised an adapter from plastic bags, cardboard and duct tape so square scrubber cartridges could fit a round socket. The crew built it from instructions read over the radio."
		},
	],
	"dust_storm": [
		{
			"title": "Spirit and Opportunity (2007)",
			"story": "A global dust storm in 2007 sharply cut the twin rovers' solar power. Engineers switched them to a minimum-power routine, and both rovers survived to keep exploring."
		},
	],
}

var _panel: PanelContainer
var _panel_style: StyleBoxFlat
var _heading_label: Label
var _detail_label: Label
var _title_label: Label
var _body_label: Label
var _current_title: String = ""
var _is_showing: bool = false
var _tween: Tween
var _connected: bool = false
var _last_shown_index: Dictionary = {}

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	visible = false
	_build_ui()
	_connect_malfunction_manager()

func _process(_delta: float) -> void:
	if not _connected:
		_connect_malfunction_manager()

func is_showing() -> bool:
	return _is_showing and visible

func current_title() -> String:
	return _current_title

func show_for(id: String) -> void:
	if not SURVIVAL_CARDS.has(id):
		return
	var cards: Array = SURVIVAL_CARDS[id]
	if cards.is_empty():
		return
	var chosen_index: int = 0
	if cards.size() > 1:
		if _last_shown_index.has(id):
			var last_idx: int = int(_last_shown_index[id])
			var offset: int = (randi() % (cards.size() - 1)) + 1
			chosen_index = (last_idx + offset) % cards.size()
		else:
			chosen_index = randi() % cards.size()
	_last_shown_index[id] = chosen_index
	var card: Dictionary = cards[chosen_index]
	_display_card(
		String(card.get("title", "")),
		"REAL CREWS SURVIVED THIS",
		"",
		String(card.get("story", "")),
		CYAN_ACCENT,
		CYAN_ACCENT
	)

func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.name = "CardPanel"
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	_panel.offset_left = 24.0
	_panel.offset_right = 404.0
	_panel.grow_horizontal = Control.GROW_DIRECTION_END
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_panel.custom_minimum_size = Vector2(380.0, 0.0)

	_panel_style = StyleBoxFlat.new()
	_panel_style.bg_color = Color(0.04, 0.06, 0.08, 0.95)
	_panel_style.set_border_width_all(2)
	_panel_style.border_color = CYAN_ACCENT
	_panel_style.set_corner_radius_all(8)
	_panel_style.set_content_margin_all(16.0)
	_panel.add_theme_stylebox_override("panel", _panel_style)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.custom_minimum_size = Vector2(344.0, 0.0)
	vbox.add_theme_constant_override("separation", 8)
	_panel.add_child(vbox)

	_heading_label = _create_label(vbox, "", 14, CYAN_ACCENT)
	_detail_label = _create_label(vbox, "", 15, Color(1.0, 0.85, 0.85))
	_detail_label.visible = false
	_title_label = _create_label(vbox, "", 22, Color(1.0, 1.0, 1.0))
	_body_label = _create_label(vbox, "", 16, Color(0.85, 0.9, 0.95))
	add_child(_panel)

func _create_label(parent: Control, text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _connect_malfunction_manager() -> void:
	if _connected:
		return
	var mm: Node = get_node_or_null("/root/MalfunctionManager")
	if mm != null and mm.has_signal("malfunction_fixed"):
		mm.malfunction_fixed.connect(_on_malfunction_fixed)
		mm.practice_mistake.connect(_on_practice_mistake)
		_connected = true

func _on_malfunction_fixed(id: String) -> void:
	show_for(id)

func _on_practice_mistake(cause_id: String, detail: String) -> void:
	var inc := _get_incident(cause_id)
	_display_card(String(inc.get("title", cause_id)), "PRACTICE: THIS WOULD HAVE KILLED YOU", detail, String(inc.get("lesson", "")), RED_ACCENT, RED_ACCENT)

func _display_card(title: String, heading: String, detail: String, body: String, border: Color, heading_color: Color) -> void:
	_current_title = title
	_panel_style.border_color = border
	_heading_label.text = heading
	_heading_label.add_theme_color_override("font_color", heading_color)
	_detail_label.text = detail
	_detail_label.visible = not detail.is_empty()
	_title_label.text = title
	_body_label.text = body
	_body_label.visible = not body.is_empty()
	_start_card_tween()

func _get_incident(cause_id: String) -> Dictionary:
	var ml: Node = get_node_or_null("/root/MissionLog")
	if ml != null and ml.has_method("incident_for"):
		return ml.incident_for(cause_id)
	if ResourceLoader.exists("res://scripts/systems/mission_log.gd"):
		var ml_script := load("res://scripts/systems/mission_log.gd") as GDScript
		if ml_script != null and "INCIDENTS" in ml_script:
			return ml_script.INCIDENTS.get(cause_id, {})
	return {}

func _start_card_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_is_showing = true
	visible = true
	_panel.modulate.a = 0.0
	_tween = create_tween()
	if _tween != null:
		_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		_tween.tween_property(_panel, "modulate:a", 1.0, 0.3)
		_tween.tween_interval(7.0)
		_tween.tween_property(_panel, "modulate:a", 0.0, 0.3)
		_tween.tween_callback(func() -> void:
			_is_showing = false
			visible = false
			_current_title = ""
		)
