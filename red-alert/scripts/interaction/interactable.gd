class_name Interactable
extends Area3D

signal interacted(by: Node)

@export var prompt_text: String = "Interact"
@export var enabled: bool = true


func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	monitoring = false


func interact(by: Node) -> void:
	if not enabled:
		return
	interacted.emit(by)

