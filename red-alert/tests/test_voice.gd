extends SceneTree

const REQUIRED_IDS := [
	"hal_wake",
	"hal_welcome_back",
	"hal_alarm_reactor",
	"hal_alarm_power",
	"hal_alarm_o2",
	"hal_warning_10",
	"hal_death",
	"hal_button_1",
	"hal_button_2",
	"hal_button_3",
	"crew_wake",
	"crew_hint_reactor",
	"crew_hint_power",
	"crew_hint_o2",
	"crew_fixed_reactor",
	"crew_fixed_power",
	"crew_fixed_o2",
	"crew_shift_done",
]


func _fail(reason: String) -> void:
	print("FAIL: " + reason)
	quit(1)


func _initialize() -> void:
	var voice: Node = root.get_node_or_null("Voice")
	if voice == null:
		voice = load("res://scripts/systems/voice.gd").new()
		root.add_child(voice)
	await process_frame

	var lines: Dictionary = voice.get("lines")
	if lines == null or lines.is_empty():
		return _fail("Voice lines dictionary is empty or not loaded")

	for id: String in REQUIRED_IDS:
		if not lines.has(id):
			return _fail("Missing voice line id: %s" % id)
		var entry: Variant = lines[id]
		if not (entry is Dictionary):
			return _fail("Voice line %s is not a dictionary" % id)
		if not entry.has("speaker") or not entry.has("text"):
			return _fail("Voice line %s missing 'speaker' or 'text'" % id)

	voice.call("say", "hal_wake")
	await create_timer(0.2, true).timeout

	if not voice.call("is_speaking"):
		return _fail("is_speaking() is false after calling say(\"hal_wake\")")

	var caption_label: Node = voice.get("caption_label")
	if caption_label == null:
		caption_label = voice.find_child("CaptionLabel", true, false)
	if caption_label == null:
		return _fail("caption label not found")

	var text: String = caption_label.get("text")
	if not text.begins_with("HAL:"):
		return _fail("Caption label text does not start with 'HAL:': %s" % text)

	print("PASS")
	quit(0)
