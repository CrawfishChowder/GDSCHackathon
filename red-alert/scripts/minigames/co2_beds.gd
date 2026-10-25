class_name CO2Beds
extends Minigame

## CO2 scrubber bed selection minigame.
## The player must switch to the regenerated and cooled bed.
## Switching to a hot or saturated bed causes fatal CO2 poisoning.

const BED_LETTERS: Array[String] = ["A", "B", "C"]

var valid_index: int = -1
var hot_index: int = -1
var saturated_index: int = -1

var saturations: Array[int] = [0, 0, 0]
var temperatures: Array[int] = [0, 0, 0]
var buttons: Array[Button] = []


func _init() -> void:
	if valid_index == -1:
		_setup_beds()


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	if valid_index == -1:
		_setup_beds()

	var content: VBoxContainer = make_panel("CO2: SWITCH SCRUBBER BEDS")
	if content == null:
		content = VBoxContainer.new()
		add_child(content)

	add_instruction(content, "Switch the air flow to the bed that is regenerated (low saturation) AND cooled below 60 °C.")

	var panel: PanelContainer = get_node_or_null("MinigamePanel") as PanelContainer
	if panel != null:
		panel.custom_minimum_size = Vector2(700, 420)
		panel.offset_left = -350.0
		panel.offset_top = -210.0
		panel.offset_right = 350.0
		panel.offset_bottom = 210.0
		_base_l = -350.0
		_base_t = -210.0
		_base_r = 350.0
		_base_b = 210.0

	var cards_box := HBoxContainer.new()
	cards_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cards_box.add_theme_constant_override("separation", 16)
	cards_box.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_child(cards_box)

	buttons.clear()
	for i: int in range(3):
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var card_style := StyleBoxFlat.new()
		card_style.bg_color = Color(0.05, 0.08, 0.11, 0.95)
		card_style.set_border_width_all(2)
		card_style.border_color = Color(0.2, 0.45, 0.55, 0.8)
		card_style.set_corner_radius_all(6)
		card_style.set_content_margin_all(14.0)
		card.add_theme_stylebox_override("panel", card_style)
		cards_box.add_child(card)

		var card_vbox := VBoxContainer.new()
		card_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		card_vbox.add_theme_constant_override("separation", 14)
		card_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		card.add_child(card_vbox)

		var header := Label.new()
		header.text = "BED %s" % BED_LETTERS[i]
		header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		header.add_theme_font_size_override("font_size", 20)
		header.add_theme_color_override("font_color", Color(0.35, 0.85, 1.0))
		card_vbox.add_child(header)

		var sat_label := Label.new()
		sat_label.text = "Saturation %d%%" % saturations[i]
		sat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sat_label.add_theme_font_size_override("font_size", 16)
		sat_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
		card_vbox.add_child(sat_label)

		var temp_label := Label.new()
		temp_label.text = "Temp %d °C" % temperatures[i]
		temp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		temp_label.add_theme_font_size_override("font_size", 16)
		temp_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
		card_vbox.add_child(temp_label)

		var btn := Button.new()
		btn.text = "Use bed %s [%d]" % [BED_LETTERS[i], i + 1]
		btn.custom_minimum_size = Vector2(0, 48)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_size_override("font_size", 15)
		btn.pressed.connect(choose.bind(i))
		card_vbox.add_child(btn)
		buttons.append(btn)


func _unhandled_input(event: InputEvent) -> void:
	if _done or not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	var keycode := key_event.keycode
	if keycode == KEY_NONE:
		keycode = key_event.physical_keycode

	var chosen_idx: int = -1
	if keycode >= KEY_1 and keycode <= KEY_3:
		chosen_idx = int(keycode - KEY_1)
	elif keycode >= KEY_KP_1 and keycode <= KEY_KP_3:
		chosen_idx = int(keycode - KEY_KP_1)

	if chosen_idx >= 0 and chosen_idx < 3:
		var vp := get_viewport()
		if vp != null:
			vp.set_input_as_handled()
		choose(chosen_idx)


func choose(i: int) -> void:
	if _done:
		return

	var sfx: Node = get_node_or_null("/root/Sfx")
	if sfx != null and sfx.has_method("play"):
		sfx.play("click")

	for btn: Button in buttons:
		if is_instance_valid(btn):
			btn.disabled = true

	if i == valid_index:
		complete()
	elif i == hot_index:
		fail("You switched to a bed that was still venting hot carbon dioxide.")
	elif i == saturated_index:
		fail("You switched to a saturated bed and carbon dioxide kept rising.")


func _setup_beds() -> void:
	var indices: Array[int] = [0, 1, 2]
	indices.shuffle()
	valid_index = indices[0]
	hot_index = indices[1]
	saturated_index = indices[2]

	saturations = [0, 0, 0]
	temperatures = [0, 0, 0]

	saturations[valid_index] = randi_range(10, 30)
	temperatures[valid_index] = randi_range(25, 45)

	saturations[hot_index] = randi_range(10, 30)
	temperatures[hot_index] = randi_range(85, 110)

	saturations[saturated_index] = randi_range(80, 98)
	temperatures[saturated_index] = randi_range(25, 45)
