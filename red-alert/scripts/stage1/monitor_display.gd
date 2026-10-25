class_name MonitorDisplay
extends Control

enum DisplayKind {
	ATMOSPHERE,
	STATUS,
	POWER,
	DOOR,
}

@export var display_kind: DisplayKind = DisplayKind.STATUS
@export var module_name: String = "MODULE"
@export var door_state: String = "SEALED"

var _lines: Array[Label] = []
var _update_timer: float = 0.0

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_display()
	_update_display()

func _process(delta: float) -> void:
	_update_timer += delta
	if _update_timer >= 0.25:
		_update_timer = 0.0
		_update_display()

func _build_display() -> void:
	var background := ColorRect.new()
	background.color = Color(0.015, 0.025, 0.045, 1.0)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 20)
	add_child(margin)

	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 8)
	margin.add_child(rows)
	match display_kind:
		DisplayKind.ATMOSPHERE:
			_add_line(rows, "ATMOSPHERE", 28, Color(0.3, 0.8, 1.0))
			_add_line(rows, "O2: 100% OK", 24, Color(0.3, 0.8, 1.0))
			_add_line(rows, "CO2 SCRUBBED: 100% OK", 24, Color(0.3, 0.8, 1.0))
		DisplayKind.STATUS:
			_add_line(rows, "HABITAT STATUS", 26, Color(0.3, 0.8, 1.0))
			_add_line(rows, "ALL SYSTEMS NOMINAL", 34, Color(0.2, 0.9, 0.3))
			_add_line(rows, "SHIFT 5:00 LEFT", 24, Color(0.3, 0.8, 1.0))
			_add_line(rows, "FIXES 0", 22, Color(0.8, 0.85, 0.9))
		DisplayKind.POWER:
			_add_line(rows, "POWER / CORE", 26, Color(0.3, 0.8, 1.0))
			_add_line(rows, "POWER: 100% OK", 20, Color(0.3, 0.8, 1.0))
			_add_line(rows, "CORE STABLE: 100% OK", 20, Color(0.3, 0.8, 1.0))
			_add_line(rows, "SOLAR: FEED OFFLINE", 18, Color(0.7, 0.75, 0.8))
			_add_line(rows, "IN SPACE NOW: --", 18, Color(0.7, 0.75, 0.8))
		DisplayKind.DOOR:
			_add_line(rows, module_name, 22, Color(0.3, 0.8, 1.0))
			_add_line(rows, door_state, 36, _state_color())
			_add_line(rows, "PRESSURE NOMINAL", 20, Color(0.7, 0.8, 0.9))

func _add_line(rows: VBoxContainer, text: String, size: int, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.modulate = color
	rows.add_child(label)
	_lines.append(label)

func _update_display() -> void:
	if _lines.is_empty():
		return
	match display_kind:
		DisplayKind.ATMOSPHERE:
			_update_atmosphere()
		DisplayKind.STATUS:
			_update_status()
		DisplayKind.POWER:
			_update_power()
		DisplayKind.DOOR:
			_lines[1].text = door_state
			_lines[1].modulate = _state_color()


func _update_atmosphere() -> void:
	var life_support := get_node_or_null("/root/LifeSupport")
	var o2 := float(life_support.call("get_level", "o2")) if life_support else 1.0
	var co2 := float(life_support.call("get_level", "co2")) if life_support else 0.0
	var o2_critical := o2 < 0.25
	var co2_critical := co2 > 0.75
	_lines[1].text = "O2: %d%% %s" % [roundi(o2 * 100.0), "CRITICAL" if o2_critical else "OK"]
	_lines[1].modulate = _critical_color(o2_critical)
	_lines[2].text = "CO2 SCRUBBED: %d%% %s" % [roundi((1.0 - co2) * 100.0), "CRITICAL" if co2_critical else "OK"]
	_lines[2].modulate = _critical_color(co2_critical)


func _update_status() -> void:
	var manager := get_node_or_null("/root/MalfunctionManager")
	if manager == null:
		return
	var active_id := String(manager.get("active_id"))
	if not String(manager.get("death_kind")).is_empty():
		_lines[1].text = "CREW LOST"
		_lines[1].modulate = Color(1.0, 0.25, 0.2)
		_lines[2].text = "MISSION FAILED"
		_lines[3].text = String(manager.get("death_detail"))
	elif not active_id.is_empty():
		_lines[1].text = String(manager.call("display_name", active_id)).to_upper()
		_lines[1].modulate = Color(1.0, 0.25, 0.2)
		var remaining := maxi(0, int(manager.get("time_left")))
		_lines[2].text = "%d:%02d" % [remaining / 60, remaining % 60]
		_lines[3].text = "GO TO: %s" % _station_for(active_id)
	else:
		_lines[1].text = "ALL SYSTEMS NOMINAL"
		_lines[1].modulate = Color(0.2, 0.9, 0.3)
		var remaining := int(manager.call("shift_time_left"))
		_lines[2].text = "SHIFT %d:%02d LEFT" % [remaining / 60, remaining % 60]
		_lines[3].text = "FIXES %d" % int(manager.get("fixes_count"))


func _update_power() -> void:
	var life_support := get_node_or_null("/root/LifeSupport")
	var power := float(life_support.call("get_level", "power")) if life_support else 1.0
	var core := float(life_support.call("get_level", "core_temp")) if life_support else 0.0
	_lines[1].text = "POWER: %d%% %s" % [roundi(power * 100.0), "CRITICAL" if power < 0.25 else "OK"]
	_lines[1].modulate = _critical_color(power < 0.25)
	_lines[2].text = "CORE STABLE: %d%% %s" % [roundi((1.0 - core) * 100.0), "CRITICAL" if core > 0.75 else "OK"]
	_lines[2].modulate = _critical_color(core > 0.75)
	var weather := get_node_or_null("/root/SpaceWeather")
	var flare: Dictionary = weather.get("latest_flare") if weather else {}
	_lines[3].text = "SOLAR: %s" % String(flare.get("class_type", "FEED OFFLINE"))
	var people := get_node_or_null("/root/PeopleInSpace")
	_lines[4].text = "IN SPACE NOW: %s" % str(people.get("count")) if people else "IN SPACE NOW: --"


func _critical_color(critical: bool) -> Color:
	return Color(1.0, 0.35, 0.2) if critical else Color(0.3, 0.8, 1.0)


func _state_color() -> Color:
	return Color(0.2, 0.9, 0.3) if door_state == "OPEN" else Color(1.0, 0.25, 0.2)


func _station_for(active_id: String) -> String:
	return {"power": "BREAKER BOX, NORTH WALL", "dust_storm": "SOLAR ARRAY, EAST WALL", "o2": "LEFT CONSOLE", "co2": "RIGHT CONSOLE"}.get(active_id, "CENTER CONSOLE")
