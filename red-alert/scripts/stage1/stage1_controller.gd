class_name Stage1Controller
extends Node3D


func _ready() -> void:
	if MalfunctionManager.mode == "story":
		var story_script := load("res://scripts/stage1/story_director.gd") as GDScript
		if story_script != null:
			add_child(story_script.new())
	MalfunctionManager.start_run()
	if not MalfunctionManager.shift_completed.is_connected(_on_shift_completed):
		MalfunctionManager.shift_completed.connect(_on_shift_completed)
	var key: Variant = get_node_or_null("MainConsole/CenterStation/EmergencyReleaseKey")
	if key != null:
		key.enabled = false


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var key_event := event as InputEventKey
	var code := key_event.physical_keycode if key_event.physical_keycode != KEY_NONE else key_event.keycode
	match code:
		KEY_F1:
			MalfunctionManager.trigger("reactor")
			get_viewport().set_input_as_handled()
		KEY_F2:
			MalfunctionManager.trigger("power")
			get_viewport().set_input_as_handled()
		KEY_F3:
			MalfunctionManager.trigger("o2")
			get_viewport().set_input_as_handled()


func _on_shift_completed() -> void:
	$BulkheadDoors/NorthBulkheadDoor.unseal()
	Voice.say("hal_relief")
	Voice.say("crew_relief")
