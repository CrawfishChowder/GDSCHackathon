class_name Stage1Controller
extends Node3D

@onready var emergency_release_key: Interactable = $MainConsole/CenterStation/EmergencyReleaseKey
@onready var north_door: BulkheadDoor = $BulkheadDoors/NorthBulkheadDoor


func _ready() -> void:
	MalfunctionManager.start_run()
	if emergency_release_key != null:
		emergency_release_key.interacted.connect(_on_emergency_release_key_interacted)


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


func _on_emergency_release_key_interacted(_by: Node) -> void:
	if north_door != null:
		north_door.unseal()
	if emergency_release_key != null:
		emergency_release_key.enabled = false

