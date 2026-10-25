class_name GameOver
extends CanvasLayer

const TUNNEL_SHADER := "shader_type canvas_item;\nuniform float radius : hint_range(0.0, 2.0) = 1.2;\nvoid fragment() { COLOR = vec4(0.0, 0.0, 0.0, smoothstep(radius - 0.35, radius, length(UV - vec2(0.5)))); }"

var _lbls: Dictionary = {}
var _panel: Control
var _flash_rect: ColorRect
var _tunnel_mat: ShaderMaterial
var _tweens: Array[Tween] = []
var _seq_running: bool = false
var _connected: bool = false

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS; layer = 20; visible = false
	_build_ui(); _connect_mission_log()

func _process(_delta: float) -> void:
	if not _connected: _connect_mission_log()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_R or event.keycode == KEY_R:
			get_viewport().set_input_as_handled()
			if _seq_running:
				skip_sequence()
			else:
				_restart()

func is_showing() -> bool: return visible and not _seq_running
func sequence_running() -> bool: return _seq_running
func skip() -> void: skip_sequence()

func skip_sequence() -> void:
	if not _seq_running: return
	_kill_tweens(); _seq_running = false
	if _flash_rect: _flash_rect.color.a = 0.0
	if _tunnel_mat: _tunnel_mat.set_shader_parameter("radius", 0.0)
	if _panel: _panel.modulate.a = 1.0

func _kill_tweens() -> void:
	for tw in _tweens: if tw and tw.is_valid(): tw.kill()
	_tweens.clear()

func _tween() -> Tween:
	var t := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tweens.append(t)
	return t

func _play_sfx(id: String) -> void:
	var sfx: Node = get_node_or_null("/root/Sfx")
	if sfx and sfx.has_method("play"): sfx.play(id)

func _full_ctrl(c: Control, p: Node = null) -> Control:
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if p: p.add_child(c)
	return c

func _build_ui() -> void:
	_tunnel_mat = ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = TUNNEL_SHADER
	_tunnel_mat.shader = sh
	_tunnel_mat.set_shader_parameter("radius", 1.2)
	_add_full_rect("TunnelVision", Color.TRANSPARENT, _tunnel_mat)
	_flash_rect = _add_full_rect("RedFlash", Color(1.0, 0.0, 0.0, 0.0))
	_panel = _full_ctrl(Control.new(), self)
	_panel.modulate.a = 0.0
	var bg := _full_ctrl(ColorRect.new(), _panel) as ColorRect
	bg.color = Color(0.12, 0.02, 0.02, 0.92)
	var center := _full_ctrl(CenterContainer.new(), _panel)
	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(700, 0)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	center.add_child(vbox)
	_add_label(vbox, "YOU DIED", 44, Color(1.0, 0.18, 0.18))
	for def in [["detail","",18,Color(1.0,0.85,0.85),true], ["stats","Survived 0:00  ·  Fixes 0",16,Color(0.75,0.75,0.75),false], ["people","",16,Color(0.75,0.75,0.75),true], ["timeline_header","SHIFT TIMELINE",14,Color(0.3,0.8,1.0),false], ["timeline","",14,Color(0.8,0.8,0.8),true], ["_","MISSION LOG",18,Color(0.3,0.8,1.0),false], ["title","",20,Color(1.0,0.9,0.4),false], ["summary","",14,Color(0.9,0.9,0.9),true], ["lesson","",14,Color(0.65,0.65,0.65),true], ["lost","",15,Color(0.85,0.45,0.45),false]]:
		var l := _add_label(vbox, def[1], def[2], def[3], def[4])
		if def[0] != "_": _lbls[def[0]] = l
	_lbls["timeline_header"].visible = false
	_lbls["timeline"].visible = false
	var sp := Control.new(); sp.custom_minimum_size = Vector2(0, 6); vbox.add_child(sp)
	var btn := Button.new()
	btn.text = "Restart [R]"; btn.custom_minimum_size = Vector2(200, 42)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_size_override("font_size", 18); btn.process_mode = PROCESS_MODE_ALWAYS
	btn.pressed.connect(func() -> void: if _seq_running: skip_sequence() else: _restart())
	vbox.add_child(btn)

func _add_full_rect(n: String, c: Color, mat: Material = null) -> ColorRect:
	var r := _full_ctrl(ColorRect.new(), self) as ColorRect
	r.name = n; r.color = c; r.material = mat
	return r

func _add_label(p: Control, text: String, sz: int, c: Color, wrap: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", c)
	if wrap: l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; l.custom_minimum_size = Vector2(700, 0)
	p.add_child(l)
	return l

func _set_opt_label(k: String, txt: String) -> void:
	_lbls[k].text = txt
	_lbls[k].visible = not txt.is_empty()

func _on_entry_added(entry: Dictionary) -> void:
	_set_opt_label("detail", String(entry.get("detail", "")))
	var s := int(entry.get("survived_seconds", 0.0))
	_lbls["stats"].text = "Survived %d:%02d  ·  Fixes %d" % [s / 60, s % 60, int(entry.get("fixes", 0))]
	var pis: Node = get_node_or_null("/root/PeopleInSpace")
	if pis: _lbls["people"].text = pis.summary_line()
	var yr := String(entry.get("year", ""))
	_set_opt_label("title", String(entry.get("title", "")) + (" (%s)" % yr if not yr.is_empty() else ""))
	_set_opt_label("summary", String(entry.get("summary", "")))
	_set_opt_label("lesson", String(entry.get("lesson", "")))
	var ml := _get_mission_log()
	_lbls["lost"].text = "Crew lost on this station: %d" % ((ml.entries as Array).size() if ml and "entries" in ml else 1)
	var tl := _format_timeline()
	_lbls["timeline_header"].visible = not tl.is_empty()
	_lbls["timeline"].text = "\n".join(tl)
	_lbls["timeline"].visible = not tl.is_empty()
	visible = true; get_tree().paused = true; Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_start_death_sequence()

func _start_death_sequence() -> void:
	_kill_tweens()
	_seq_running = true; _panel.modulate.a = 0.0; _flash_rect.color.a = 0.5
	_tunnel_mat.set_shader_parameter("radius", 1.2)
	_tween().tween_property(_flash_rect, "color:a", 0.0, 0.25)
	_tween().tween_property(_tunnel_mat, "shader_parameter/radius", 0.0, 2.0).from(1.2)
	var tw_s := _tween()
	tw_s.tween_interval(2.6)
	tw_s.tween_callback(func() -> void: _seq_running = false)
	tw_s.tween_property(_panel, "modulate:a", 1.0, 0.4)
	var tw_a := _tween()
	for g in [0.0, 0.5, 0.8]:
		if g > 0.0: tw_a.tween_interval(g)
		tw_a.tween_callback(_play_sfx.bind("heartbeat"))
	tw_a.tween_interval(1.2)
	tw_a.tween_callback(_play_sfx.bind("flatline"))

func _restart() -> void:
	_kill_tweens(); _seq_running = false; get_tree().paused = false
	get_tree().reload_current_scene()

func _connect_mission_log() -> void:
	if _connected: return
	var ml := _get_mission_log()
	if ml and ml.has_signal("entry_added"):
		ml.entry_added.connect(_on_entry_added); _connected = true

func _get_mission_log() -> Node: return get_node_or_null("/root/MissionLog")
func _get_mm() -> Node: return get_node_or_null("/root/MalfunctionManager")

func _format_timeline(custom_hist: Array = []) -> PackedStringArray:
	var lines := PackedStringArray()
	var hist: Array = custom_hist
	if hist.is_empty():
		var mm := _get_mm()
		if not mm or not ("history" in mm): return lines
		hist = mm.history
	var count := hist.size()
	for i in range(maxi(0, count - 8), count):
		var rec: Dictionary = hist[i]
		var s := int(rec.get("start", 0.0))
		var dn := String(rec.get("name", rec.get("id", "")))
		var out := String(rec.get("outcome", ""))
		if out == "fixed":
			var dur := int(round(maxf(0.0, float(rec.get("end", s)) - float(rec.get("start", s)))))
			lines.append("%d:%02d  %s  fixed in %ds" % [s / 60, s % 60, dn, dur])
		elif out == "fatal":
			lines.append("%d:%02d  %s  FATAL" % [s / 60, s % 60, dn])
		elif out == "practice_mistake":
			lines.append("%d:%02d  %s  practice mistake" % [s / 60, s % 60, dn])
		else:
			lines.append("%d:%02d  %s  %s" % [s / 60, s % 60, dn, out])
	return lines
