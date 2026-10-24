class_name Stage1Controller
extends Node3D

@onready var emergency_release_key: Interactable = $MainConsole/CenterStation/EmergencyReleaseKey
@onready var north_door: BulkheadDoor = $BulkheadDoors/NorthBulkheadDoor


func _ready() -> void:
	emergency_release_key.interacted.connect(_on_emergency_release_key_interacted)


func _on_emergency_release_key_interacted(_by: Node) -> void:
	north_door.unseal()
	emergency_release_key.enabled = false

