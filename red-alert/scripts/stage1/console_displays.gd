extends Node3D

var _left_display: MonitorDisplay
var _center_display: MonitorDisplay
var _right_display: MonitorDisplay
var _left_o2: Label
var _left_co2: Label
var _center_status: Label
var _center_line1: Label
var _center_line2: Label
var _right_power: Label
var _right_core: Label
var _right_solar: Label
var _right_pis: Label
var _update_timer: float = 0.0


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS

	_left_display = _make_display("LeftDisplay", Vector3(-2.1, 2.2, 4.47))
	var lv := _vbox(_left_display.setup(Vector2(1.36, 0.60), Vector2i(512, 256)))
	_lbl(lv, "ATMOSPHERE", 28, Color(0.3, 0.8, 1.0))
	_left_o2 = _lbl(lv, "O2: 100% OK", 24, Color(0.3, 0.8, 1.0))
	_left_co2 = _lbl(lv, "CO2 SCRUBBED: 100% OK", 24, Color(0.3, 0.8, 1.0))

	_center_display = _make_display("CenterDisplay", Vector3(0.0, 2.25, 4.445))
	var cv := _vbox(_center_display.setup(Vector2(1.68, 0.74), Vector2i(512, 256)))
	_lbl(cv, "HABITAT STATUS", 26, Color(0.3, 0.8, 1.0))
	_center_status = _lbl(cv, "ALL SYSTEMS NOMINAL", 36, Color(0.2, 0.9, 0.3))
	_center_line1 = _lbl(cv, "SHIFT 5:00 LEFT", 26, Color(0.3, 0.8, 1.0))
	_center_line2 = _lbl(cv, "FIXES 0", 22, Color(0.8, 0.85, 0.9))

	_right_display = _make_display("RightDisplay", Vector3(2.1, 2.2, 4.47))
	var rv := _vbox(_right_display.setup(Vector2(1.36, 0.60), Vector2i(512, 256)))
	_lbl(rv, "POWER / CORE", 26, Color(0.3, 0.8, 1.0))
	_right_power = _lbl(rv, "POWER: 100% OK", 20, Color(0.3, 0.8, 1.0))
	_right_core = _lbl(rv, "CORE STABLE: 100% OK", 20, Color(0.3, 0.8, 1.0))
	_right_solar = _lbl(rv, "SOLAR: FEED OFFLINE", 18, Color(0.7, 0.75, 0.8))
	_right_pis = _lbl(rv, "IN SPACE NOW: --", 18, Color(0.7, 0.75, 0.8))

	_update_displays()


func _process(delta: float) -> void:
	_update_timer += delta
	if _update_timer >= 0.25:
		_update_timer = 0.0
		_update_displays()


func _make_display(dname: String, pos: Vector3) -> MonitorDisplay:
	var disp := MonitorDisplay.new()
	disp.name = dname
	disp.position = pos
	disp.rotation = Vector3(0.0, PI, 0.0)
	add_child(disp)
	return disp


func _vbox(root: Control) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 16)
	root.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)
	return vbox


func _lbl(vbox: VBoxContainer, txt: String, fsz: int, col: Color) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", fsz)
	l.modulate = col
	vbox.add_child(l)
	return l


func _update_displays() -> void:
	var ls := get_node_or_null("/root/LifeSupport")
	var mm := get_node_or_null("/root/MalfunctionManager")

	var o2: float = float(ls.call("get_level", "o2")) if ls and ls.has_method("get_level") else 1.0
	var co2: float = float(ls.call("get_level", "co2")) if ls and ls.has_method("get_level") else 0.0
	var o2_crit: bool = bool(ls.call("is_critical", "o2")) if ls and ls.has_method("is_critical") else (o2 < 0.25)
	var co2_crit: bool = bool(ls.call("is_critical", "co2")) if ls and ls.has_method("is_critical") else (co2 > 0.75)
	_left_o2.text = "O2: %d%% %s" % [clampi(int(round(o2 * 100.0)), 0, 100), "CRITICAL" if o2_crit else "OK"]
	_left_o2.modulate = Color(1.0, 0.35, 0.2) if o2_crit else Color(0.3, 0.8, 1.0)
	_left_co2.text = "CO2 SCRUBBED: %d%% %s" % [clampi(int(round((1.0 - co2) * 100.0)), 0, 100), "CRITICAL" if co2_crit else "OK"]
	_left_co2.modulate = Color(1.0, 0.35, 0.2) if co2_crit else Color(0.3, 0.8, 1.0)

	if mm != null and String(mm.get("death_kind")) != "":
		_center_status.text = "CREW LOST"
		_center_status.modulate = Color(1.0, 0.25, 0.2)
		_center_line1.text = "MISSION FAILED"
		_center_line2.text = String(mm.get("death_detail"))
	elif mm != null and String(mm.get("active_id")) != "":
		var aid: String = String(mm.get("active_id"))
		var dn: String = String(mm.call("display_name", aid)) if mm.has_method("display_name") else aid
		_center_status.text = (aid if dn.is_empty() else dn).to_upper()
		_center_status.modulate = Color(1.0, 0.25, 0.2)
		var tl: int = int(maxf(0.0, float(mm.get("time_left"))))
		_center_line1.text = "%d:%02d" % [tl / 60, tl % 60]
		_center_line1.modulate = Color(1.0, 0.35, 0.2)
		var st := "BREAKER BOX, NORTH WALL" if aid == "power" else ("LEFT CONSOLE" if aid == "o2" else "CENTER CONSOLE")
		_center_line2.text = "GO TO: %s" % st
		_center_line2.modulate = Color(1.0, 0.85, 0.2)
	else:
		_center_status.text = "ALL SYSTEMS NOMINAL"
		_center_status.modulate = Color(0.2, 0.9, 0.3)
		var sl: int = int(float(mm.call("shift_time_left"))) if mm and mm.has_method("shift_time_left") else 300
		_center_line1.text = "SHIFT %d:%02d LEFT" % [sl / 60, sl % 60]
		_center_line1.modulate = Color(0.3, 0.8, 1.0)
		_center_line2.text = "FIXES %d" % (int(mm.get("fixes_count")) if mm else 0)
		_center_line2.modulate = Color(0.8, 0.85, 0.9)

	var pwr: float = float(ls.call("get_level", "power")) if ls and ls.has_method("get_level") else 1.0
	var core: float = float(ls.call("get_level", "core_temp")) if ls and ls.has_method("get_level") else 0.0
	var pwr_crit: bool = bool(ls.call("is_critical", "power")) if ls and ls.has_method("is_critical") else (pwr < 0.25)
	var core_crit: bool = bool(ls.call("is_critical", "core_temp")) if ls and ls.has_method("is_critical") else (core > 0.75)
	_right_power.text = "POWER: %d%% %s" % [clampi(int(round(pwr * 100.0)), 0, 100), "CRITICAL" if pwr_crit else "OK"]
	_right_power.modulate = Color(1.0, 0.35, 0.2) if pwr_crit else Color(0.3, 0.8, 1.0)
	_right_core.text = "CORE STABLE: %d%% %s" % [clampi(int(round((1.0 - core) * 100.0)), 0, 100), "CRITICAL" if core_crit else "OK"]
	_right_core.modulate = Color(1.0, 0.35, 0.2) if core_crit else Color(0.3, 0.8, 1.0)

	var sw := get_node_or_null("/root/SpaceWeather")
	var fl: Dictionary = sw.get("latest_flare") if sw and sw.get("latest_flare") is Dictionary else {}
	var ct: String = String(fl.get("class_type", ""))
	_right_solar.text = ("SOLAR: %s (NASA DONKI)" % ct) if not ct.is_empty() else "SOLAR: FEED OFFLINE"

	var pis := get_node_or_null("/root/PeopleInSpace")
	var cnt: int = int(pis.get("count")) if pis else -1
	_right_pis.text = ("IN SPACE NOW: %d" % cnt) if cnt >= 0 else "IN SPACE NOW: --"
