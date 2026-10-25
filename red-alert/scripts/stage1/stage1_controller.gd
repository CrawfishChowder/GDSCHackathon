# Stage1Controller: Root controller for Stage 1 habitat shift.
# Starts the shift run, routes F1-F3 emergency triggers, and unseals north exit on completion.
# Listens to MalfunctionManager.shift_completed.
class_name Stage1Controller
extends Node3D


func _ready() -> void:
	var mm: Node = get_node_or_null("/root/MalfunctionManager") if is_inside_tree() else null
	if mm != null and String(mm.get("mode")) == "story":
		var story_script := load("res://scripts/stage1/story_director.gd") as GDScript
		if story_script != null:
			add_child(story_script.new())
	if mm != null:
		if mm.has_method("start_run"):
			mm.call("start_run")
		if mm.has_signal("shift_completed") and not mm.shift_completed.is_connected(_on_shift_completed):
			mm.shift_completed.connect(_on_shift_completed)
	var key: Variant = get_node_or_null("MainConsole/CenterStation/EmergencyReleaseKey")
	if key != null and "enabled" in key:
		key.enabled = false


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var mm: Node = get_node_or_null("/root/MalfunctionManager") if is_inside_tree() else null
	if mm == null or not mm.has_method("trigger"):
		return
	var key_event := event as InputEventKey
	var code: Key = key_event.physical_keycode if key_event.physical_keycode != KEY_NONE else key_event.keycode
	match code:
		KEY_F1:
			mm.call("trigger", "reactor")
			var vp := get_viewport()
			if vp != null:
				vp.set_input_as_handled()
		KEY_F2:
			mm.call("trigger", "power")
			var vp := get_viewport()
			if vp != null:
				vp.set_input_as_handled()
		KEY_F3:
			mm.call("trigger", "o2")
			var vp := get_viewport()
			if vp != null:
				vp.set_input_as_handled()


func _on_shift_completed() -> void:
	var door: Node = get_node_or_null("BulkheadDoors/NorthBulkheadDoor")
	if door != null and door.has_method("unseal"):
		door.call("unseal")
	var voice: Node = get_node_or_null("/root/Voice") if is_inside_tree() else null
	if voice != null and voice.has_method("say"):
		voice.call("say", "hal_relief")
		voice.call("say", "crew_relief")
